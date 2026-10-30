import AVKit
import SwiftUI

@MainActor
final class LivePlayerLayerCoordinator:
  NSObject, @preconcurrency AVPlayerViewControllerDelegate
{
  var hostedViews: [UIView] = []
  var controller: LivePlayerController
  var orientationObservation: NSObjectProtocol?
  var playbackIntentObservation: NSKeyValueObservation?
  var pendingPauseIntentTask: Task<Void, Never>?
  var resumeAfterTransitionTask: Task<Void, Never>?
  var settleTransitionTask: Task<Void, Never>?
  var playbackWasIntended = false
  var fullScreenPlaybackWasIntended = false
  var isFullScreenPresented = false
  var isEndingFullScreen = false
  var presentationTransitionInProgress = false
  var sponsorCenterConstraint: NSLayoutConstraint?
  var sponsorTrailingConstraint: NSLayoutConstraint?
  let surfaceGestures: LivePlayerSurfaceGestures
  var pictureInPictureUIRestoreHandler:
    (((@escaping (Bool) -> Void)) -> Void)? = nil

  init(controller: LivePlayerController) {
    self.controller = controller
    surfaceGestures = LivePlayerSurfaceGestures(controller: controller)
    super.init()
    observePlaybackIntent()
    observeDeviceOrientation()
  }

  func install(in playerController: AVPlayerViewController) {
    guard hostedViews.isEmpty,
      let overlay = playerController.contentOverlayView
    else {
      return
    }

    let danmakuView = UIHostingConfiguration {
      LiveDanmakuOverlay(controller: controller)
    }
    .margins(.all, 0)
    .makeContentView()
    danmakuView.backgroundColor = .clear
    danmakuView.isUserInteractionEnabled = false
    danmakuView.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(danmakuView)
    // 999, not required: required pins fight AVKit's control layout.
    let danmakuPins = [
      danmakuView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
      danmakuView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
      danmakuView.topAnchor.constraint(equalTo: overlay.topAnchor),
      danmakuView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
    ]
    danmakuPins.forEach { $0.priority = .init(999) }
    NSLayoutConstraint.activate(danmakuPins)

    hostedViews = [danmakuView]
  }

  func update(
    _ controller: LivePlayerController,
    in playerController: AVPlayerViewController
  ) {
    guard self.controller !== controller else { return }
    self.controller = controller
    surfaceGestures.controller = controller
    observePlaybackIntent()
    remove()
    install(in: playerController)
  }

  func invalidate() {
    pendingPauseIntentTask?.cancel()
    resumeAfterTransitionTask?.cancel()
    settleTransitionTask?.cancel()
    playbackIntentObservation = nil
    if let orientationObservation {
      NotificationCenter.default.removeObserver(orientationObservation)
      self.orientationObservation = nil
    }
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
    remove()
  }

  func remove() {
    hostedViews.forEach { $0.removeFromSuperview() }
    hostedViews.removeAll()
    sponsorCenterConstraint = nil
    sponsorTrailingConstraint = nil
  }
}
