import SwiftUI

struct LiveNativeFullscreenView: View {
  @ObservedObject var controller: LivePlayerController
  let onClose: () -> Void
  @StateObject private var controls = LiveNativeControlsState()
  // Hold-to-boost + horizontal seek, same rules as the inline player.
  @State private var speedBoostRate: Float?
  @State private var boostBaseRate: Float?
  @State private var seekPreview: TimeInterval?
  @State private var seekStartPosition: TimeInterval?

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      if let playback = controller.nativePlayback {
        LiveNativeVideoView(playback: playback, controller: controller, surface: .fullscreen)
          .ignoresSafeArea()
          .contentShape(Rectangle())
          .onTapGesture { controls.tap() }
          .gesture(holdBoostGesture)
          .gesture(fullscreenDragGesture)
      }
      LiveNativeSubtitleOverlay(controller: controller)
      hud
      LiveNativePlayerControls(controller: controller, controls: controls, isFullscreen: true) {
        onClose()
      }
    }
    .onChange(of: controller.nativePlayback == nil) {
      if controller.nativePlayback == nil { onClose() }
    }
    .accessibilityIdentifier("live.player.fullscreen")
  }

  /// Long-press boosts to 2x, then the vertical drag ramps 1x–4x in half
  /// steps; releasing restores the previous rate.
  private var holdBoostGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.35)
      .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
      .onChanged { value in
        guard case let .second(true, drag) = value, let drag else { return }
        if boostBaseRate == nil {
          boostBaseRate = controller.playbackRate
          speedBoostRate = 2
          controller.setPlaybackRate(2)
        }
        let raw = 2.0 + (-drag.translation.height / 100.0) * 2.0
        let stepped = (raw * 2).rounded() / 2
        let rate = Float(min(max(stepped, 1), 4))
        speedBoostRate = rate
        controller.setPlaybackRate(rate)
      }
      .onEnded { _ in
        if let base = boostBaseRate {
          controller.setPlaybackRate(base)
        }
        boostBaseRate = nil
        speedBoostRate = nil
      }
  }

  /// Horizontal drag = relative seek preview; a big downward drag drops
  /// back to the player page. Sideways drags stay with the seek.
  private var fullscreenDragGesture: some Gesture {
    DragGesture(minimumDistance: 25)
      .onChanged { value in
        guard abs(value.translation.width) >= abs(value.translation.height) else { return }
        if seekStartPosition == nil { seekStartPosition = controller.position }
        let delta = Double(value.translation.width / 8)
        seekPreview = max(0, min(controller.duration, seekStartPosition! + delta))
        controls.keepVisible()
      }
      .onEnded { value in
        if let target = seekPreview, value.translation.height <= 120 {
          controller.seek(to: target)
        } else if value.translation.height > 120,
          abs(value.translation.width) < value.translation.height {
          onClose()
        }
        seekPreview = nil
        seekStartPosition = nil
      }
  }

  @ViewBuilder
  private var hud: some View {
    if let rate = speedBoostRate {
      VStack(spacing: 10) {
        Text("\(rate, specifier: "%.1f")×")
          .font(.system(size: 34, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
        Text("Hold • drag up for speed")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .transition(.opacity)
    } else if let preview = seekPreview {
      VStack(spacing: 6) {
        Text(LivePlaybackChapterNavigator.clockText(seconds: Int(preview)))
          .font(.system(size: 26, weight: .semibold, design: .rounded))
          .foregroundStyle(.white)
        Text("\(Int(preview - controller.position))s")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .transition(.opacity)
    }
  }
}

// A presented controller that forces landscape only until it has appeared;
// afterwards the window is free to rotate back out again.
final class LiveLandscapeHostingController: UIHostingController<LiveNativeFullscreenView> {
  static weak var active: LiveLandscapeHostingController?
  static var isForcingLandscape = false

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    guard traitCollection.userInterfaceIdiom == .phone else { return .all }
    return Self.isForcingLandscape ? .landscape : .allButUpsideDown
  }

  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    .landscapeRight
  }

  var onDisappear: (() -> Void)?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Force satisfied: hand the window back so rotating to portrait can
    // leave fullscreen again.
    Self.isForcingLandscape = false
    setNeedsUpdateOfSupportedInterfaceOrientations()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    onDisappear?()
    Self.active = nil
  }

  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }

  @MainActor
  static func present(for controller: LivePlayerController) {
    guard active == nil, !controller.isPresentingFullscreen else { return }
    AppLogger.playback
      .info("fullscreen: present requested")
    controller.pictureInPicture.uninstallNativeContent()
    controller.isPresentingFullscreen = true
    Task { @MainActor in
      // Only rotate first when the window is still portrait; entering by
      // rotating already lands on a landscape window and presents at once.
      if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
        isForcingLandscape = true
        LiveScreenOrientation.set(.landscape)
        try? await Task.sleep(for: .milliseconds(220))
      }
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
          active?.dismiss(animated: true)
        }
      )
      created.modalPresentationStyle = .fullScreen
      // Cross-fade in and out instead of popping the full screen in, so
      // the window rotation and the modal read as one move.
      created.modalTransitionStyle = .crossDissolve
      created.onDisappear = {
        AppLogger.playback
          .info("fullscreen: host disappeared")
        controller.isPresentingFullscreen = false
        // The entry rotation owns the return; a rotation-enter never left
        // portrait, and this resets to a no-op there.
        LiveScreenOrientation.set(.portrait)
      }
      host = created
      active = created
      top.present(created, animated: true)
    }
  }
}
