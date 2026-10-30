import SwiftUI

extension LiveMiniPlayerView {
  @ViewBuilder
  func videoLayer(_ video: LiveVideoItem, controller: LivePlayerController) -> some View {
    if controller.audioOnly {
      ZStack {
        // No .scaledToFill on LiveRemoteImage: it inflates the card and pushes the controls out of reach.
        LiveRemoteImage(url: video.thumbnail)
          .blur(radius: 18)
          .opacity(0.5)
          .clipped()
        Image(systemName: "waveform")
          .font(.system(size: 26, weight: .medium))
          .foregroundStyle(.white)
      }
      .clipped()
    } else if let playback = controller.nativePlayback {
      LiveNativeVideoView(playback: playback, controller: controller, surface: .mini)
    } else if controller.state == .playing || controller.state == .paused {
      LiveVideoPreviewLayer(player: controller.player)
    } else {
      LiveRemoteImage(url: video.thumbnail)
    }
  }

  func controls(_ controller: LivePlayerController) -> some View {
    VStack(spacing: 0) {
      HStack {
        glassButton("xmark", label: "Close player", identifier: "live.miniplayer.close", diameter: 36) {
          coordinator.close()
        }
        Spacer()
        glassButton(
          "arrow.up.left.and.arrow.down.right",
          label: "Expand player",
          identifier: "live.miniplayer.expand",
          diameter: 36,
          action: onExpand
        )
      }
      Spacer()
      HStack(spacing: 18) {
        glassButton(
          "gobackward.10",
          label: "Seek backward 10 seconds",
          identifier: "live.miniplayer.rewind",
          diameter: 48
        ) {
          controller.seek(to: controller.position - 10)
        }
        MiniPlayPauseButton(controller: controller, diameter: 64)
        glassButton(
          "goforward.10",
          label: "Seek forward 10 seconds",
          identifier: "live.miniplayer.forward",
          diameter: 48
        ) {
          controller.seek(to: controller.position + 10)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }

  private func glassButton(
    _ systemName: String,
    label: LocalizedStringKey,
    identifier: String,
    diameter: CGFloat,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: diameter * 0.38, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: diameter, height: diameter)
        .pipGlassBackground()
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityIdentifier(identifier)
  }
}
