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
      LiveNativePlayerControls(controller: controller, controls: controls, isFullscreen: true) {
        onClose()
      }
    }
    .onChange(of: controller.nativePlayback == nil) {
      if controller.nativePlayback == nil { onClose() }
    }
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
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      var top = scene.keyWindow?.rootViewController
    else {
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
    created.onDisappear = { [weak controller] in controller?.isPresentingFullscreen = false }
    controller.isPresentingFullscreen = true
    host = created
    top.present(created, animated: true)
  }
}
