import SwiftUI

struct LiveNativeFullscreenView: View {
  @ObservedObject var controller: LivePlayerController
  let onClose: () -> Void
  @StateObject private var controls = LiveNativeControlsState()

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
        onClose()
      }
    }
    .onChange(of: controller.nativePlayback == nil) {
      if controller.nativePlayback == nil { onClose() }
    }
    .gesture(
      // Dragging down drops back to the player page, like every system
      // full-screen video. Sideways drags stay with the seek gestures.
      DragGesture(minimumDistance: 30)
        .onEnded { value in
          guard value.translation.height > 120,
            abs(value.translation.width) < value.translation.height
          else { return }
          onClose()
        }
    )
    .accessibilityIdentifier("live.player.fullscreen")
  }
}

// A presented controller that only allows landscape makes iOS rotate in and back out of it.
final class LiveLandscapeHostingController: UIHostingController<LiveNativeFullscreenView> {
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    traitCollection.userInterfaceIdiom == .phone ? .landscape : .all
  }

  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    .landscapeRight
  }

  var onDisappear: (() -> Void)?

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    onDisappear?()
  }

  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }

  @MainActor
  static func present(for controller: LivePlayerController) {
    AppLogger.playback
      .info("fullscreen: present requested")
    controller.pictureInPicture.uninstallNativeContent()
    controller.isPresentingFullscreen = true
    Task { @MainActor in
      // Rotate the window first: presenting a modal into a portrait window
      // shows no rotation transition, so the fullscreen lands on an
      // already-landscape window.
      LiveScreenOrientation.set(.landscape)
      try? await Task.sleep(for: .milliseconds(280))
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
          host?.dismiss(animated: true)
        }
      )
      created.modalPresentationStyle = .fullScreen
      created.onDisappear = {
        AppLogger.playback
          .info("fullscreen: host disappeared")
        controller.isPresentingFullscreen = false
        // The window was rotated on entry; the dismissal owns the return.
        LiveScreenOrientation.set(.portrait)
      }
      host = created
      top.present(created, animated: true)
    }
  }
}
