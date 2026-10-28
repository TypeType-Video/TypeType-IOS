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
    // The chrome rides the flag: it fades in with the growth and out with
    // the collapse through the same coordinator-synced transaction.
    .opacity(controller.isPresentingFullscreen ? 1 : 0)
    .accessibilityIdentifier("live.player.fullscreen")
  }
}

// A presented controller that only allows landscape makes iOS rotate in and back out of it.
final class LiveLandscapeHostingController: UIHostingController<LiveNativeFullscreenView> {
  static weak var active: LiveLandscapeHostingController?
  static var presentPending = false
  static let growthDuration: TimeInterval = 0.32

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
      LiveScreenOrientation.set(.portrait)
      host.dismiss(animated: true)
      // One motion: the stage collapse rides the dismissal and the return
      // rotation through the transition coordinator, not after them.
      let controller = host.controller
      if let coordinator = host.transitionCoordinator {
        coordinator.animate(alongsideTransition: { _ in
          withAnimation(.easeInOut(duration: coordinator.transitionDuration)) {
            controller?.isPresentingFullscreen = false
          }
        })
      } else {
        controller?.isPresentingFullscreen = false
      }
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
  var onRotate: ((LiveLandscapeHostingController, UIViewControllerTransitionCoordinator) -> Void)?

  override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    onRotate?(self, coordinator)
  }

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
    guard !presentPending, active == nil else {
      AppLogger.playback.info("fullscreen: present ignored (already pending or hosted)")
      return
    }
    presentPending = true
    controller.pictureInPicture.uninstallNativeContent()
    Task { @MainActor in
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }),
        var top = scene.keyWindow?.rootViewController
      else {
        presentPending = false
        return
      }
      while let presented = top.presentedViewController {
        top = presented
      }
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
        if controller.isPresentingFullscreen {
          withAnimation(.easeInOut(duration: growthDuration)) {
            controller.isPresentingFullscreen = false
          }
        }
        // The window was rotated on entry; the dismissal owns the return.
        LiveScreenOrientation.set(.portrait)
      }
      // One motion: the stage growth, the metadata collapse and the chrome
      // fade ride the system rotation through its transition coordinator.
      created.onRotate = { host, coordinator in
        guard !host.isBeingDismissed, !controller.isPresentingFullscreen else { return }
        AppLogger.playback.info(
          "fullscreen: rotation hook fired duration=\(coordinator.transitionDuration, privacy: .public)"
        )
        coordinator.animate(alongsideTransition: { _ in
          withAnimation(.easeInOut(duration: coordinator.transitionDuration)) {
            controller.isPresentingFullscreen = true
          }
        })
      }
      active = created
      presentPending = false
      AppLogger.playback.info(
        "fullscreen: presenting host top=\(String(describing: type(of: top)), privacy: .public)"
      )
      top.present(created, animated: false)
      if scene.interfaceOrientation.isLandscape {
        // Rotating by hand already brought the window into landscape: the
        // growth has no rotation to ride, so run it directly.
        withAnimation(.easeInOut(duration: growthDuration)) {
          controller.isPresentingFullscreen = true
        }
      } else {
        // The presented controller is the top one now and allows landscape:
        // ask for the rotation; onRotate grows the stage alongside it.
        LiveScreenOrientation.set(.landscape)
        created.setNeedsUpdateOfSupportedInterfaceOrientations()
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(450))
          guard !controller.isPresentingFullscreen, active === created else { return }
          AppLogger.playback.info("fullscreen: rotation hook missed, growing on fallback timer")
          withAnimation(.easeInOut(duration: growthDuration)) {
            controller.isPresentingFullscreen = true
          }
        }
      }
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(400))
        AppLogger.playback.info(
          "fullscreen: present settled presented=\(created.presentingViewController != nil, privacy: .public) inWindow=\(created.viewIfLoaded?.window != nil, privacy: .public) isBeingDismissed=\(created.isBeingDismissed, privacy: .public)"
        )
      }
    }
  }
}
