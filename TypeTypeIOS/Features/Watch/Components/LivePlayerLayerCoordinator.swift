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
    NSLayoutConstraint.activate([
      danmakuView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
      danmakuView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
      danmakuView.topAnchor.constraint(equalTo: overlay.topAnchor),
      danmakuView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
    ])

    let sponsorView = UIHostingConfiguration {
      LiveSponsorBlockOverlay(
        controller: controller,
        fillsAvailableSpace: false
      )
    }
    .margins(.all, 0)
    .makeContentView()
    sponsorView.backgroundColor = .clear
    sponsorView.setContentCompressionResistancePriority(
      .required,
      for: .horizontal
    )
    sponsorView.setContentCompressionResistancePriority(
      .required,
      for: .vertical
    )
    sponsorView.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(sponsorView)
    let center = sponsorView.centerXAnchor.constraint(
      equalTo: overlay.centerXAnchor
    )
    let trailing = sponsorView.trailingAnchor.constraint(
      equalTo: overlay.trailingAnchor,
      constant: -10
    )
    NSLayoutConstraint.activate([
      center,
      sponsorView.topAnchor.constraint(
        equalTo: overlay.topAnchor,
        constant: 10
      ),
      sponsorView.leadingAnchor.constraint(
        greaterThanOrEqualTo: overlay.leadingAnchor,
        constant: 10
      ),
      sponsorView.trailingAnchor.constraint(
        lessThanOrEqualTo: overlay.trailingAnchor,
        constant: -10
      ),
      sponsorView.bottomAnchor.constraint(
        lessThanOrEqualTo: overlay.bottomAnchor
      ),
    ])
    sponsorCenterConstraint = center
    sponsorTrailingConstraint = trailing
    hostedViews = [danmakuView, sponsorView]
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
}
