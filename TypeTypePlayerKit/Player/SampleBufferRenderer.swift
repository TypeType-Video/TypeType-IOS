import AVFoundation

// AVFoundation's renderers and synchronizer accept calls from any thread.
final class SampleBufferRenderer: @unchecked Sendable {
  let displayLayer: AVSampleBufferDisplayLayer
  // Newer SDKs mark the layer's renderer main-actor isolated; the engine
  // lives off the main queue, so the renderer is captured once here and
  // marked unsafe-nonisolated, matching how AVFoundation actually treats it.
  private nonisolated(unsafe) let videoRenderer: AVSampleBufferVideoRenderer
  let audioRenderer = AVSampleBufferAudioRenderer()
  let synchronizer = AVSampleBufferRenderSynchronizer()
  private let feedQueue = DispatchQueue(label: "dev.typetype.player.feed", qos: .userInitiated)

  @MainActor
  init() {
    displayLayer = AVSampleBufferDisplayLayer()
    displayLayer.videoGravity = .resizeAspect
    // The engine decides when there is enough data; a delayed start would keep the old clock time.
    synchronizer.delaysRateChangeUntilHasSufficientMediaData = false
    videoRenderer = displayLayer.sampleBufferRenderer
    synchronizer.addRenderer(videoRenderer)
    synchronizer.addRenderer(audioRenderer)
    audioRenderer.audioTimePitchAlgorithm = .timeDomain
  }

  var currentTime: CMTime { synchronizer.currentTime() }
  var rate: Float { synchronizer.rate }

  func enqueue(_ buffer: CMSampleBuffer, for kind: MP4TrackKind) {
    switch kind {
    case .video: videoRenderer.enqueue(buffer)
    case .audio: audioRenderer.enqueue(buffer)
    }
  }

  func isReady(for kind: MP4TrackKind) -> Bool {
    switch kind {
    case .video: videoRenderer.isReadyForMoreMediaData
    case .audio: audioRenderer.isReadyForMoreMediaData
    }
  }

  func waitUntilReady(for kind: MP4TrackKind) async {
    guard !isReady(for: kind) else { return }
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let once = OnceFlag()
      let request: @Sendable () -> Void = { [weak self] in
        guard once.claim() else { return }
        self?.stopRequesting(kind)
        continuation.resume()
      }
      switch kind {
      case .video: videoRenderer.requestMediaDataWhenReady(on: feedQueue, using: request)
      case .audio: audioRenderer.requestMediaDataWhenReady(on: feedQueue, using: request)
      }
    }
  }

  private func stopRequesting(_ kind: MP4TrackKind) {
    switch kind {
    case .video: videoRenderer.stopRequestingMediaData()
    case .audio: audioRenderer.stopRequestingMediaData()
    }
  }

  func waitUntil(_ time: CMTime) async {
    let once = OnceFlag()
    let box = ObserverBox()
    await withTaskCancellationHandler {
      await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        let resume: @Sendable () -> Void = { [weak self] in
          guard once.claim() else { return }
          if let observer = box.take() { self?.synchronizer.removeTimeObserver(observer) }
          continuation.resume()
        }
        box.set(synchronizer.addBoundaryTimeObserver(forTimes: [NSValue(time: time)], queue: feedQueue, using: resume))
        box.onCancel = resume
        if Task.isCancelled || currentTime >= time { resume() }
      }
    } onCancel: {
      box.cancel()
    }
  }

  func flush() {
    videoRenderer.flush()
    audioRenderer.flush()
  }

  func setRate(_ rate: Float, time: CMTime? = nil) {
    if let time {
      synchronizer.setRate(rate, time: time)
    } else {
      synchronizer.rate = rate
    }
  }

  var failure: Error? {
    videoRenderer.error ?? audioRenderer.error
  }

  var requiresVideoFlush: Bool {
    videoRenderer.requiresFlushToResumeDecoding
  }
}

final class OnceFlag: @unchecked Sendable {
  private let lock = NSLock()
  private var claimed = false

  func claim() -> Bool {
    lock.withLock {
      guard !claimed else { return false }
      claimed = true
      return true
    }
  }
}

final class ObserverBox: @unchecked Sendable {
  private let lock = NSLock()
  private var observer: Any?
  private var cancelHandler: (() -> Void)?

  var onCancel: (() -> Void)? {
    get { lock.withLock { cancelHandler } }
    set { lock.withLock { cancelHandler = newValue } }
  }

  func set(_ value: Any) {
    lock.withLock { observer = value }
  }

  func take() -> Any? {
    lock.withLock {
      defer { observer = nil }
      return observer
    }
  }

  func cancel() {
    let handler = lock.withLock { cancelHandler }
    handler?()
  }
}
