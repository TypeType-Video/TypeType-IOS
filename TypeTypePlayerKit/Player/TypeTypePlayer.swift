import AVFoundation

@MainActor
public final class TypeTypePlayer {
  public private(set) var state: TypeTypePlayerState = .idle
  public var onStateChange: ((TypeTypePlayerState) -> Void)?
  public var onStart: (() -> Void)?
  public var onTime: ((TimeInterval) -> Void)?

  private let renderer: SampleBufferRenderer
  private let engine: PlaybackEngine
  private var timeObserver: Any?
  private var prepareTask: Task<Void, Never>?

  public init(source: MediaSegmentSource, configuration: TypeTypePlayerConfiguration = TypeTypePlayerConfiguration()) {
    let renderer = SampleBufferRenderer()
    self.renderer = renderer
    var forward: ((PlaybackEngineEvent) -> Void)?
    engine = PlaybackEngine(source: source, renderer: renderer, configuration: configuration) { event in
      Task { @MainActor in forward?(event) }
    }
    forward = { [weak self] event in self?.apply(event) }
    timeObserver = renderer.synchronizer.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 2),
      queue: .main
    ) { [weak self] time in
      MainActor.assumeIsolated { self?.onTime?(time.seconds) }
    }
  }

  public var videoLayer: AVSampleBufferDisplayLayer { renderer.displayLayer }
  public var currentTime: TimeInterval { max(renderer.currentTime.seconds, 0) }
  public var isMuted: Bool {
    get { renderer.audioRenderer.isMuted }
    set { renderer.audioRenderer.isMuted = newValue }
  }
  public var volume: Float {
    get { renderer.audioRenderer.volume }
    set { renderer.audioRenderer.volume = newValue }
  }

  public func start(at time: TimeInterval, autoplay: Bool) {
    prepareTask?.cancel()
    prepareTask = Task { [engine] in
      do {
        try await engine.prepare(at: time, autoplay: autoplay)
      } catch is CancellationError {
        return
      } catch {
        await MainActor.run { self.apply(.state(.failed(String(describing: error)))) }
      }
    }
  }

  public func play() {
    Task { [engine] in await engine.play() }
  }

  public func pause() {
    Task { [engine] in await engine.pause() }
  }

  public func seek(to time: TimeInterval) {
    Task { [engine] in await engine.seek(to: time) }
  }

  public func setRate(_ rate: Float) {
    Task { [engine] in await engine.setRate(rate) }
  }

  public func setVideoEnabled(_ enabled: Bool) {
    Task { [engine] in await engine.setTrack(.video, enabled: enabled) }
  }

  public func recoverDecoderIfNeeded() {
    Task { [engine] in await engine.recoverDecoderIfNeeded() }
  }

  public func stop() {
    prepareTask?.cancel()
    if let timeObserver {
      renderer.synchronizer.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }
    Task { [engine] in await engine.stop() }
  }

  private func apply(_ event: PlaybackEngineEvent) {
    switch event {
    case .started:
      onStart?()
    case let .state(newState):
      guard newState != state else { return }
      state = newState
      onStateChange?(newState)
    }
  }
}
