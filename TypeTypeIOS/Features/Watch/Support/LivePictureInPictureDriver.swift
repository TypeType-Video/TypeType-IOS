import AVFoundation
import AVKit
import UIKit

@MainActor
final class LivePictureInPictureDriver: NSObject, ObservableObject {
  @Published private(set) var isEngaged = false
  @Published private(set) var isPendingStart = false
  var isSystemActive: Bool {
    pipController?.isPictureInPictureActive ?? false
  }
  var onChange: (() -> Void)?

  private var pipController: AVPictureInPictureController?
  private var contentLayer: AVPlayerLayer?
  private var nativeLayer: AVSampleBufferDisplayLayer?
  private weak var hostView: UIView?
  private var isRestoring = false
  private var controlsRefreshPending = false
  private var didStartConfirmed = false
  private var startVerificationTask: Task<Void, Never>?
  private var pendingStartTask: Task<Void, Never>?
  private var onRestore: (() -> Void)?
  private var onClose: (() -> Void)?

  var isAvailable: Bool {
    AVPictureInPictureController.isPictureInPictureSupported()
  }

  func installContentLayer(on view: UIView, player: AVPlayer) {
    if contentLayer == nil {
      let layer = AVPlayerLayer()
      layer.videoGravity = .resizeAspect
      layer.isHidden = true
      contentLayer = layer
    }
    if nativeLayer != nil || pipController == nil, let layer = contentLayer {
      nativeLayer = nil
      pipController = isAvailable ? AVPictureInPictureController(playerLayer: layer) : nil
      pipController?.delegate = self
      pipController?.canStartPictureInPictureAutomaticallyFromInline = false
    }
    contentLayer?.player = player
    contentLayer?.isHidden = !isEngaged
    if contentLayer?.superlayer !== view.layer {
      contentLayer?.removeFromSuperlayer()
      view.layer.insertSublayer(contentLayer ?? CALayer(), at: 0)
    }
    hostView = view
    relayout()
  }

  func loadPoster(url: URL?) async {
    guard let url else { return }
    let posterStart = DispatchTime.now()
    defer {
      let ms = Int(Double(DispatchTime.now().uptimeNanoseconds - posterStart.uptimeNanoseconds) / 1e6)
      AppLogger.playback.info("pip timing: poster took \(ms, privacy: .public)ms")
      Self.lastTimingLog = "poster \(ms)ms | " + Self.lastTimingLog
    }
    let image: UIImage? = await withTaskGroup(
      of: UIImage?.self
    ) { group in
      group.addTask {
        guard let (data, _) = try? await URLSession.shared.data(from: url)
        else { return nil }
        return UIImage(data: data)
      }
      group.addTask {
        try? await Task.sleep(for: .milliseconds(1_200))
        return nil
      }
      let first = await group.next() ?? nil
      group.cancelAll()
      return first
    }
    guard let image, let cgImage = image.cgImage else { return }
    contentLayer?.contents = cgImage
    contentLayer?.contentsGravity = .resizeAspect
  }

  func installNativeContent(
    layer: AVSampleBufferDisplayLayer,
    playback: AVPictureInPictureSampleBufferPlaybackDelegate
  ) {
    guard isAvailable, nativeLayer !== layer else { return }
    contentLayer?.isHidden = true
    nativeLayer = layer
    let controller = AVPictureInPictureController(
      contentSource: .init(sampleBufferDisplayLayer: layer, playbackDelegate: playback)
    )
    controller.delegate = self
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    AppLogger.playback
      .info("pip engine: native content installed")
    pipController = controller
  }

  func invalidatePlaybackState() {
    if nativeLayer != nil {
      pipController?.invalidatePlaybackState()
    }
  }

  func relayout() {
    guard let hostView, let contentLayer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    contentLayer.frame = hostView.bounds
    CATransaction.commit()
  }

  func markControlsRefresh() {
    controlsRefreshPending = true
  }

  func consumeControlsRefresh() -> Bool {
    defer { controlsRefreshPending = false }
    return controlsRefreshPending
  }

  private var startRequestedAt: DispatchTime?
  nonisolated(unsafe) static var lastTimingLog = ""

  func start(
    onRestore: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    startRequestedAt = DispatchTime.now()
    guard isAvailable, let pipController, !isEngaged, !isPendingStart else {
      return
    }
    relayout()
    if nativeLayer == nil {
      contentLayer?.isHidden = false
    }
    self.onRestore = onRestore
    self.onClose = onClose
    if pipController.isPictureInPicturePossible {
      performStart()
    } else {
      isPendingStart = true
      onChange?()
      pendingStartTask?.cancel()
      pendingStartTask = Task { @MainActor [weak self] in
        let possible = await pipController.becomesPossible(within: .seconds(15))
        guard let self, isPendingStart, !Task.isCancelled else { return }
        isPendingStart = false
        if possible {
          performStart()
        } else {
          onChange?()
        }
      }
    }
  }

  private func performStart() {
    guard let pipController else { return }
    relayout()
    contentLayer?.isHidden = false
    isEngaged = true
    didStartConfirmed = false
    onChange?()
    let startCall = DispatchTime.now()
    pipController.startPictureInPicture()
    let startMs = Int(
      Double(DispatchTime.now().uptimeNanoseconds - startCall.uptimeNanoseconds) / 1e6
    )
    AppLogger.playback
      .info("pip timing: startPictureInPicture blocked \(startMs, privacy: .public)ms")
    Self.lastTimingLog = "start blocked \(startMs)ms | " + Self.lastTimingLog
    startVerificationTask?.cancel()
    startVerificationTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1.5))
      guard let self, isEngaged, !didStartConfirmed else { return }
      isEngaged = false
      contentLayer?.isHidden = true
      onChange?()
    }
  }

  func cancelPendingStart() {
    isPendingStart = false
    pendingStartTask?.cancel()
    pendingStartTask = nil
    onChange?()
  }

  func stop() {
    pipController?.stopPictureInPicture()
  }

  func bringInline() {
    AppLogger.playback.info("pip driver: bring inline requested")
    let systemActive = pipController?.isPictureInPictureActive ?? false
    guard isEngaged || systemActive else {
      AppLogger.playback.info("pip driver: bring inline skipped, not engaged")
      return
    }
    isEngaged = false
    onChange?()
    isRestoring = true
    relayout()
    pipController?.stopPictureInPicture()
  }
}

extension LivePictureInPictureDriver: AVPictureInPictureControllerDelegate {
  nonisolated func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      didStartConfirmed = true
      isEngaged = true
      if let requestedAt = startRequestedAt {
        let ms = Int(Double(DispatchTime.now().uptimeNanoseconds - requestedAt.uptimeNanoseconds) / 1e6)
        AppLogger.playback
          .info("pip timing: request to confirmed took \(ms, privacy: .public)ms")
        Self.lastTimingLog = "confirm \(ms)ms | " + Self.lastTimingLog
      }
      onChange?()
    }
  }

  nonisolated func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      isEngaged = false
      contentLayer?.isHidden = true
      onChange?()
    }
  }

  nonisolated func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
      completionHandler: @escaping (Bool) -> Void
  ) {
    Task { @MainActor [weak self] in
      guard let self else {
        completionHandler(false)
        return
      }
      isRestoring = true
      AppLogger.playback.info("pip driver: restore requested")
      onRestore?()
      completionHandler(true)
    }
  }

  nonisolated func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      isEngaged = false
      contentLayer?.isHidden = true
      controlsRefreshPending = true
      let wasRestoring = isRestoring
      isRestoring = false
      AppLogger.playback
        .info("pip driver: did stop, restoring=\(wasRestoring, privacy: .public)")
      onChange?()
      if !wasRestoring {
        onClose?()
      }
    }
  }
}
