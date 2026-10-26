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
  var swipeGestureHandler: ((PlayerSwipeAdjustmentEvent) -> Void)?
  var horizontalSeekHandler: ((PlayerHorizontalSeekEvent) -> Void)?
  var pictureInPictureUIRestoreHandler:
    (((@escaping (Bool) -> Void)) -> Void)? = nil
  private var swipeGestureKind: PlayerSwipeAdjustmentKind?
  private var swipeGestureBaseFraction: CGFloat = 0.5
  private var horizontalSeekBasePosition: TimeInterval = 0

  init(controller: LivePlayerController) {
    self.controller = controller
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
    // Priority 999 on purpose: required pins inside AVKit's overlay subtree
    // fight AVKit's control-container layout; full-size autoresizing in turn
    // covered the controls with the (clear) hosting view. Soft pins keep the
    // danmaku matched to the video without either failure mode.
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

  func installSwipeGesture(in view: UIView) {
    let recognizer = UIPanGestureRecognizer(
      target: self,
      action: #selector(handleSwipeGesture(_:))
    )
    recognizer.cancelsTouchesInView = false
    recognizer.delegate = self
    view.addGestureRecognizer(recognizer)
  }

  func installHorizontalSeekGesture(in view: UIView) {
    let recognizer = UIPanGestureRecognizer(
      target: self,
      action: #selector(handleHorizontalSeekGesture(_:))
    )
    recognizer.cancelsTouchesInView = false
    recognizer.delegate = self
    view.addGestureRecognizer(recognizer)
  }

  @objc private func handleHorizontalSeekGesture(
    _ recognizer: UIPanGestureRecognizer
  ) {
    guard let view = recognizer.view,
      view.bounds.width > 0,
      controller.duration > 0
    else { return }

    let translation = recognizer.translation(in: view)
    let progress = min(
      max(translation.x / view.bounds.width, -0.45),
      0.45
    )
    let target = min(
      max(horizontalSeekBasePosition + progress * controller.duration, 0),
      controller.duration
    )

    switch recognizer.state {
    case .began:
      horizontalSeekHandler?(.began(position: horizontalSeekBasePosition))
    case .changed:
      horizontalSeekHandler?(.updated(position: target))
    case .ended, .cancelled, .failed:
      horizontalSeekHandler?(.ended(position: target))
      horizontalSeekBasePosition = controller.position
    default:
      break
    }
  }

  @objc private func handleSwipeGesture(
    _ recognizer: UIPanGestureRecognizer
  ) {
    switch recognizer.state {
    case .began:
      guard let kind = swipeGestureKind else { return }
      swipeGestureHandler?(
        .began(kind: kind, fraction: swipeGestureBaseFraction)
      )
    case .changed:
      guard let kind = swipeGestureKind,
        let view = recognizer.view
      else { return }
      let translation = recognizer.translation(in: view)
      let translationVector = CGSize(
        width: translation.x,
        height: translation.y
      )
      let fraction = PlayerSwipeAdjustmentRules.fraction(
        base: swipeGestureBaseFraction,
        translationHeight: translationVector.height,
        height: view.bounds.height
      )
      swipeGestureHandler?(
        .updated(kind: kind, fraction: fraction)
      )
    case .ended, .cancelled, .failed:
      swipeGestureKind = nil
      swipeGestureHandler?(.ended)
    default:
      break
    }
  }
}

extension LivePlayerLayerCoordinator: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(
    _ gestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer,
      let view = recognizer.view,
      view.bounds.width > 0,
      view.bounds.height > 0
    else { return false }

    let startLocation = recognizer.location(in: view)
    let translation = recognizer.translation(in: view)
    let isHorizontalSeek = abs(translation.x) > 14
      && abs(translation.x) > abs(translation.y) * 1.25
    if isHorizontalSeek {
      guard LiveAppPreferencesStore.shared.preferences.playerSwipeSeekEnabled,
        controller.duration > 0
      else { return false }
      horizontalSeekBasePosition = controller.position
      return true
    }
    guard let kind = PlayerSwipeAdjustmentRules.kind(
      startLocation: startLocation,
      size: view.bounds.size,
      translation: CGSize(width: translation.x, height: translation.y)
    ) else { return false }

    swipeGestureKind = kind
    swipeGestureBaseFraction = switch kind {
    case .brightness:
      CGFloat(UIScreen.main.brightness)
    case .volume:
      CGFloat(controller.nativePlayback?.player.volume ?? controller.player.volume)
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
      UIGestureRecognizer
  ) -> Bool {
    true
  }
}
