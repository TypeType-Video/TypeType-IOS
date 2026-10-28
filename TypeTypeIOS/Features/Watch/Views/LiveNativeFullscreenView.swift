import SwiftUI

struct LiveNativeFullscreenView: View {
  @ObservedObject var controller: LivePlayerController
  let onClose: () -> Void
  @StateObject private var controls = LiveNativeControlsState()
  @State private var wasLandscape = false
  // Rotation is a control: turning the phone to portrait leaves fullscreen.
  // Debounced — mid-turn sensor samples pass through portrait.
  @State private var portraitRotationExit: Task<Void, Never>?

  var body: some View {
    ZStack {
      // The video stays in the PAGE surface behind this controller: the
      // modal is a transparent orientation authority holding only the
      // chrome, so the picture never swaps surfaces and rides the rotation.
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { controls.tap() }
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
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
      switch UIDevice.current.orientation {
      case .portrait:
        guard portraitRotationExit == nil else { return }
        portraitRotationExit = Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(350))
          guard !Task.isCancelled else { return }
          AppLogger.playback.info("fullscreen: onClose via rotation-portrait")
          onClose()
        }
      default:
        portraitRotationExit?.cancel()
        portraitRotationExit = nil
      }
    }
    .onAppear { UIDevice.current.beginGeneratingDeviceOrientationNotifications() }
    .onDisappear { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
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
      // Relax the landscape hold exactly for the return so the portrait
      // rotation animates together with the dismissal instead of snapping
      // in after the fade.
      host.relaxesForExit = true
      host.setNeedsUpdateOfSupportedInterfaceOrientations()
      // The page surface shrinks with the return rotation (its layout
      // change animates on the page); this controller only fades chrome.
      host.controller?.isPresentingFullscreen = false
      LiveScreenOrientation.set(.portrait)
      host.dismiss(animated: true)
    }
  }

  var relaxesForExit = false
  weak var controller: LivePlayerController?

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if traitCollection.userInterfaceIdiom != .phone { return .all }
    return relaxesForExit ? .allButUpsideDown : .landscape
  }

  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    // Match the side the user already holds so entry needs no flip.
    // Device and interface landscape sides are mirrored in UIKit.
    switch UIDevice.current.orientation {
    case .landscapeLeft: return .landscapeRight
    case .landscapeRight: return .landscapeLeft
    default: return .landscapeRight
    }
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
      // shows no rotation transition. The short wait lets the rotation
      // animation start so the modal's fade rides its tail — one motion.
      LiveScreenOrientation.set(.landscape)
      try? await Task.sleep(for: .milliseconds(80))
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
      // overFullScreen keeps the page surface attached below — it renders
      // the picture for the whole transition (a removed presenter blanks).
      // The controller is transparent: it only floats chrome above the
      // growing page surface, so the cross-fade fades controls, not video.
      created.modalPresentationStyle = .overFullScreen
      created.view.backgroundColor = .clear
      created.controller = controller
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
