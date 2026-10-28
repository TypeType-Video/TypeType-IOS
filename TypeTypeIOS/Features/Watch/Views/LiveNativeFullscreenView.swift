import SwiftUI

struct LiveNativeFullscreenView: View {
  @ObservedObject var controller: LivePlayerController
  let onClose: () -> Void
  @StateObject private var controls = LiveNativeControlsState()
  @State private var wasLandscape = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      if let playback = controller.nativePlayback {
        LiveNativeVideoView(playback: playback, controller: controller, surface: .fullscreen)
          .ignoresSafeArea()
          .onTapGesture { controls.tap() }
      }
      LiveNativeSubtitleOverlay(controller: controller)
      LiveNativePlayerControls(controller: controller, controls: controls, isFullscreen: true) {
        AppLogger.playback.info("fullscreen: onClose via exit-button")
        onClose()
      }
    }
    .onChange(of: controller.nativePlayback == nil) {
      if controller.nativePlayback == nil {
        AppLogger.playback.info("fullscreen: onClose via playback-nil")
        onClose()
      }
    }
    // The system can rotate the window out from under this landscape-locked
    // modal when the phone is turned. Own geometry is the truth: once the
    // modal has been landscape, turning portrait dismisses it.
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { size in
      let landscape = size.width > size.height
      if landscape {
        wasLandscape = true
      } else if wasLandscape {
        AppLogger.playback.info("fullscreen: onClose via geometry-portrait")
        onClose()
      }
    }
    .gesture(
      // Dragging down drops back to the player page, like every system
      // full-screen video. Sideways drags stay with the seek gestures.
      DragGesture(minimumDistance: 30)
        .onEnded { value in
          guard value.translation.height > 120,
            abs(value.translation.width) < value.translation.height
          else { return }
          AppLogger.playback.info("fullscreen: onClose via modal-drag")
          onClose()
        }
    )
    .accessibilityIdentifier("live.player.fullscreen")
  }
}

// A presented controller that only allows landscape makes iOS rotate in and back out of it.
final class LiveLandscapeHostingController: UIHostingController<LiveNativeFullscreenView> {
  static weak var active: LiveLandscapeHostingController?

  static func dismissActive(reason: String = "unspecified") {
    let host = active
    AppLogger.playback.info(
      "fullscreen: dismissActive reason=\(reason, privacy: .public) host=\(host != nil, privacy: .public) isBeingDismissed=\(host?.isBeingDismissed ?? false, privacy: .public) isBeingPresented=\(host?.isBeingPresented ?? false, privacy: .public) hostInWindow=\(host?.viewIfLoaded?.window != nil, privacy: .public) presenting=\(host?.presentingViewController != nil, privacy: .public)"
    )
    if let host, !host.isBeingDismissed {
      host.dismiss(animated: true)
    }
  }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    traitCollection.userInterfaceIdiom == .phone ? .landscape : .all
  }

  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    .landscapeRight
  }

  var onDisappear: (() -> Void)?

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    AppLogger.playback.info(
      "fullscreen: viewDidDisappear animated=\(animated, privacy: .public) presentingGone=\(self.presentingViewController == nil, privacy: .public)"
    )
    onDisappear?()
  }

  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }

  @MainActor
  static func present(for controller: LivePlayerController) {
    AppLogger.playback
      .info("fullscreen: present requested flag=\(controller.isPresentingFullscreen, privacy: .public) host=\(active != nil, privacy: .public)")
    controller.pictureInPicture.uninstallNativeContent()
    controller.isPresentingFullscreen = true
    Task { @MainActor in
      // Rotate the window first: presenting a modal into a portrait window
      // shows no rotation transition, so the fullscreen lands on an
      // already-landscape window.
      LiveScreenOrientation.set(.landscape)
      try? await Task.sleep(for: .milliseconds(220))
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }),
        var top = scene.keyWindow?.rootViewController
      else {
        controller.isPresentingFullscreen = false
        return
      }
      while let presented = top.presentedViewController {
        top = presented
      }
      weak var host: LiveLandscapeHostingController?
      let created = LiveLandscapeHostingController(
        rootView: LiveNativeFullscreenView(controller: controller) {
          AppLogger.playback.info("fullscreen: onClose closure fired")
          LiveLandscapeHostingController.dismissActive(reason: "modal-onClose")
        }
      )
      created.modalPresentationStyle = .fullScreen
      // Cross-fade in and out instead of popping the full screen in, so
      // the window rotation and the modal read as one move.
      created.modalTransitionStyle = .crossDissolve
      created.onDisappear = {
        AppLogger.playback
          .info("fullscreen: host disappeared flag=\(controller.isPresentingFullscreen, privacy: .public)")
        controller.isPresentingFullscreen = false
        // The window was rotated on entry; the dismissal owns the return.
        LiveScreenOrientation.set(.portrait)
      }
      host = created
      active = created
      AppLogger.playback.info(
        "fullscreen: presenting host top=\(String(describing: type(of: top)), privacy: .public)"
      )
      top.present(created, animated: true)
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(400))
        AppLogger.playback.info(
          "fullscreen: present settled presented=\(created.presentingViewController != nil, privacy: .public) inWindow=\(created.viewIfLoaded?.window != nil, privacy: .public) isBeingDismissed=\(created.isBeingDismissed, privacy: .public)"
        )
      }
    }
  }
}
