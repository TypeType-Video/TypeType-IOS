import SwiftUI

struct LiveNativePlayerControls: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var controls: LiveNativeControlsState
  var isFullscreen = false
  var onFullscreen: () -> Void
  @State private var scrubPosition: TimeInterval?

  var body: some View {
    ZStack {
      if showsControls {
        LinearGradient(
          colors: [.black.opacity(0.35), .clear, .black.opacity(0.55)],
          startPoint: .top,
          endPoint: .bottom
        )
        .allowsHitTesting(false)
        playPauseButton
        timeline
          .frame(maxHeight: .infinity, alignment: .bottom)
      }
    }
    .animation(.easeOut(duration: 0.18), value: showsControls)
    .onChange(of: controller.state) {
      if controller.state == .playing {
        controls.scheduleHide()
      } else {
        controls.keepVisible()
      }
    }
  }

  private var showsControls: Bool {
    switch controller.state {
    case .ready, .paused: return true
    case .playing: return controls.visible || scrubPosition != nil
    case .idle, .loading, .failed: return false
    }
  }

  private var playPauseButton: some View {
    Button {
      controller.togglePlayback()
      controls.scheduleHide()
    } label: {
      Image(systemName: controller.state == .playing ? "pause.fill" : "play.fill")
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 64, height: 64)
        .background(.ultraThinMaterial, in: Circle())
        .environment(\.colorScheme, .dark)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(controller.state == .playing ? "Pause" : "Play")
    .accessibilityIdentifier("live.player.play-pause")
  }

  private var timeline: some View {
    HStack(spacing: 10) {
      Text(LivePlaybackChapterNavigator.clockText(seconds: Int(scrubPosition ?? controller.position)))
      Slider(
        value: Binding(
          get: { scrubPosition ?? controller.position },
          set: { scrubPosition = $0 }
        ),
        in: 0...max(controller.duration, 1)
      ) { editing in
        if editing {
          controls.keepVisible()
        } else if let target = scrubPosition {
          controller.seek(to: target)
          scrubPosition = nil
          controls.scheduleHide()
        }
      }
      .tint(.white)
      .accessibilityLabel("Playback position")
      .accessibilityIdentifier("live.player.timeline")
      Text(LivePlaybackChapterNavigator.clockText(seconds: Int(controller.duration)))
      Button {
        onFullscreen()
      } label: {
        Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
          .font(.system(size: 15, weight: .semibold))
          .frame(width: 32, height: 32)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isFullscreen ? "Exit full screen" : "Full screen")
      .accessibilityIdentifier("live.player.fullscreen-toggle")
    }
    .font(.caption2)
    .monospacedDigit()
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
    .padding(.bottom, 6)
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
