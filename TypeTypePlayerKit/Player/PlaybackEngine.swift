import AVFoundation
import OSLog

enum PlaybackEngineEvent: Sendable {
  case state(TypeTypePlayerState)
  case started
}

actor PlaybackEngine {
  static let log = Logger(subsystem: "dev.typetype.playerkit", category: "engine")
  struct TrackState {
    let info: MP4TrackInfo
    let format: CMFormatDescription
    var bufferedEnd: CMTime = .invalid
    var fetchedEnd: CMTime = .invalid
    var ended = false
    var task: Task<Void, Never>?
  }

  let source: MediaSegmentSource
  let renderer: SampleBufferRenderer
  let configuration: TypeTypePlayerConfiguration
  let emit: @Sendable (PlaybackEngineEvent) -> Void

  var tracks: [MP4TrackKind: TrackState] = [:]
  var generation = 0
  var startTime: CMTime = .zero
  var wantsPlay = false
  var rate: Float = 1
  var clockStarted = false
  var stalled = false
  var stalledAt: ContinuousClock.Instant?
  var ended = false
  var watchTask: Task<Void, Never>?
  var startWaiters: [CheckedContinuation<Void, Never>] = []
  var alignmentWaiters: [CheckedContinuation<Void, Never>] = []

  init(
    source: MediaSegmentSource,
    renderer: SampleBufferRenderer,
    configuration: TypeTypePlayerConfiguration,
    emit: @escaping @Sendable (PlaybackEngineEvent) -> Void
  ) {
    self.source = source
    self.renderer = renderer
    self.configuration = configuration
    self.emit = emit
  }

  func prepare(at time: TimeInterval, autoplay: Bool) async throws {
    wantsPlay = autoplay
    emit(.state(.buffering))
    try await withThrowingTaskGroup(of: (MP4TrackKind, TrackState).self) { group in
      for kind in source.trackKinds {
        group.addTask { [source] in
          let data = try await source.initSegment(for: kind)
          guard let info = try MP4InitSegment.tracks(in: data).first(where: { $0.kind == kind }) else {
            throw MP4Error.missingBox("trak")
          }
          return (kind, TrackState(info: info, format: try MP4FormatDescription.make(for: info)))
        }
      }
      for try await (kind, state) in group {
        tracks[kind] = state
      }
    }
    startPipelines(at: time)
  }

  func play() {
    wantsPlay = true
    if ended {
      return
    }
    if clockStarted, !stalled {
      renderer.setRate(rate)
      emit(.state(.playing))
    }
  }

  func pause() {
    wantsPlay = false
    renderer.setRate(0)
    if !ended {
      emit(.state(.paused))
    }
  }

  func setRate(_ newRate: Float) {
    rate = newRate
    if clockStarted, wantsPlay, !stalled, !ended {
      renderer.setRate(newRate)
    }
  }

  func seek(to time: TimeInterval) {
    Self.log.notice("seek gen=\(self.generation) to \(time) now=\(self.renderer.currentTime.seconds)")
    renderer.setRate(0, time: CMTime(seconds: max(time, 0), preferredTimescale: 90_000))
    renderer.flush()
    emit(.state(.buffering))
    startPipelines(at: time)
  }

  func stop() {
    generation += 1
    cancelWork()
    renderer.setRate(0)
    renderer.flush()
    resumeStartWaiters()
    resumeAlignmentWaiters()
  }

  func recoverDecoderIfNeeded() {
    guard renderer.requiresVideoFlush else { return }
    seek(to: max(renderer.currentTime.seconds, 0))
  }

  func startPipelines(at time: TimeInterval) {
    generation += 1
    cancelWork()
    resumeStartWaiters()
    resumeAlignmentWaiters()
    clockStarted = false
    stalled = false
    stalledAt = nil
    ended = false
    startTime = CMTime(seconds: max(time, 0), preferredTimescale: 90_000)
    let current = generation
    for kind in tracks.keys {
      tracks[kind]?.bufferedEnd = .invalid
      tracks[kind]?.fetchedEnd = .invalid
      tracks[kind]?.ended = false
      tracks[kind]?.task = Task { await self.runTrack(kind, generation: current) }
    }
  }

  func cancelWork() {
    watchTask?.cancel()
    watchTask = nil
    for kind in tracks.keys {
      tracks[kind]?.task?.cancel()
      tracks[kind]?.task = nil
    }
  }

  func fail(_ error: Error, generation failed: Int) {
    guard failed == generation else { return }
    generation += 1
    cancelWork()
    renderer.setRate(0)
    Self.log.error("playback failed: \(String(describing: error), privacy: .public)")
    emit(.state(.failed(String(describing: error))))
  }
}
