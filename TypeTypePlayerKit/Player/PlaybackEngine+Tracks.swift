import AVFoundation

extension PlaybackEngine {
  func runTrack(_ kind: MP4TrackKind, generation current: Int) async {
    do {
      let start = startTime.seconds
      let firstSequence = try await retrying(current) { [source] in
        try await source.firstSequence(for: kind, at: start)
      }
      var sequence = firstSequence
      var data = try await locateStart(kind, sequence: &sequence, generation: current)
      while let segment = data {
        let prepared = try prepare(segment, kind: kind)
        async let committed: Void = commit(prepared, kind: kind, generation: current)
        try await waitForAlignment(kind, generation: current)
        let next = sequence + 1
        let upcoming = try await fetch(kind, next, generation: current)
        try await committed
        data = upcoming
        sequence = next
      }
      guard current == generation else { return }
      tracks[kind]?.ended = true
      resumeAlignmentWaiters()
      clockMayChange()
    } catch is CancellationError {
      return
    } catch {
      fail(error, generation: current)
    }
  }

  // A source may estimate the first sequence; the fragment's own times confirm or move it.
  private func locateStart(
    _ kind: MP4TrackKind,
    sequence: inout Int,
    generation current: Int
  ) async throws -> Data? {
    let tolerance = CMTime(value: 1, timescale: 10)
    var data = try await fetch(kind, sequence, generation: current)
    for _ in 0..<6 {
      guard let segment = data, let span = try presentationSpan(segment, kind: kind) else { return data }
      if span.start > startTime + tolerance, sequence > 1 {
        sequence -= 1
      } else if span.end <= startTime {
        sequence += 1
      } else {
        return segment
      }
      data = try await fetch(kind, sequence, generation: current)
    }
    return data
  }

  private func presentationSpan(_ data: Data, kind: MP4TrackKind) throws -> (start: CMTime, end: CMTime)? {
    guard let track = tracks[kind] else { return nil }
    let samples = try MP4Fragment.samples(in: data, tracks: [track.info])[track.info.trackID] ?? []
    guard let first = samples.min(by: { $0.presentationTime < $1.presentationTime }),
      let last = samples.max(by: { $0.presentationTime < $1.presentationTime })
    else {
      return nil
    }
    let scale = CMTimeScale(track.info.timescale)
    return (
      CMTime(value: first.presentationTime, timescale: scale),
      CMTime(value: last.presentationTime + Int64(last.duration), timescale: scale)
    )
  }

  private func fetch(_ kind: MP4TrackKind, _ sequence: Int, generation current: Int) async throws -> Data? {
    try await retrying(current) { [source] in
      try await source.segment(for: kind, sequence: sequence)
    }
  }

  private func retrying<T: Sendable>(
    _ current: Int,
    _ operation: @Sendable () async throws -> T
  ) async throws -> T {
    let deadline = ContinuousClock.now + configuration.retryWindow
    var delay: Duration = .milliseconds(500)
    while true {
      try checkCurrent(current)
      do {
        return try await operation()
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        guard ContinuousClock.now + delay < deadline else { throw error }
        try await Task.sleep(for: delay)
        delay = min(delay * 2, .seconds(5))
      }
    }
  }

  private func prepare(_ data: Data, kind: MP4TrackKind) throws -> (buffer: CMSampleBuffer, end: CMTime)? {
    guard let track = tracks[kind] else { return nil }
    let scale = CMTimeScale(track.info.timescale)
    let startValue = CMTimeConvertScale(startTime, timescale: scale, method: .roundTowardNegativeInfinity).value
    var samples = try MP4Fragment.samples(in: data, tracks: [track.info])[track.info.trackID] ?? []
    if kind == .audio {
      samples.removeAll { $0.presentationTime + Int64($0.duration) <= startValue }
    }
    guard let last = samples.max(by: { $0.presentationTime < $1.presentationTime }) else { return nil }
    let end = CMTime(value: last.presentationTime + Int64(last.duration), timescale: scale)
    tracks[kind]?.fetchedEnd = end
    resumeAlignmentWaiters()
    let buffer = try MP4SampleBuffers.make(
      samples: samples,
      data: data,
      timescale: track.info.timescale,
      format: track.format,
      hiddenBefore: kind == .video ? startTime : nil
    )
    return (buffer, end)
  }

  private func commit(
    _ prepared: (buffer: CMSampleBuffer, end: CMTime)?,
    kind: MP4TrackKind,
    generation current: Int
  ) async throws {
    guard let prepared else { return }
    try await waitForSpace(kind, generation: current)
    await renderer.waitUntilReady(for: kind)
    try checkCurrent(current)
    renderer.enqueue(prepared.buffer, for: kind)
    if let failure = renderer.failure { throw failure }
    tracks[kind]?.bufferedEnd = prepared.end
    clockMayChange()
  }

  // The server repositions its pump on every segment it has to wait for: requests from both
  // tracks must stay near the same time, or the pump swings between them and stalls.
  private func waitForAlignment(_ kind: MP4TrackKind, generation current: Int) async throws {
    let slack = CMTime(value: 1, timescale: 1)
    while true {
      try checkCurrent(current)
      guard let own = tracks[kind]?.fetchedEnd, own.isValid else { return }
      let others = tracks.filter { $0.key != kind && !$0.value.ended }.map(\.value.fetchedEnd)
      guard let behind = others.min(by: { !$0.isValid || ($1.isValid && $0 < $1) }) else { return }
      if behind.isValid, own - behind <= slack { return }
      await withCheckedContinuation { alignmentWaiters.append($0) }
    }
  }

  func resumeAlignmentWaiters() {
    let waiters = alignmentWaiters
    alignmentWaiters = []
    waiters.forEach { $0.resume() }
  }

  private func waitForSpace(_ kind: MP4TrackKind, generation current: Int) async throws {
    while true {
      try checkCurrent(current)
      guard let end = tracks[kind]?.bufferedEnd, end.isValid else { return }
      let reference = clockStarted ? renderer.currentTime : startTime
      let goal = CMTime(seconds: configuration.forwardBuffer, preferredTimescale: 600)
      guard end - reference >= goal else { return }
      if clockStarted {
        await renderer.waitUntil(end - goal)
      } else {
        await withCheckedContinuation { startWaiters.append($0) }
      }
    }
  }

  func checkCurrent(_ current: Int) throws {
    if Task.isCancelled || current != generation {
      throw CancellationError()
    }
  }

  func resumeStartWaiters() {
    let waiters = startWaiters
    startWaiters = []
    waiters.forEach { $0.resume() }
  }
}
