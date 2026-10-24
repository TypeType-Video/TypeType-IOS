import AVFoundation
import SwiftUI

struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void
  @State private var dragTranslation: CGFloat = 0

  var body: some View {
    if let video = coordinator.currentVideo,
      let controller = coordinator.controller {
      ZStack {
        if controller.audioOnly {
          ZStack {
            LiveRemoteImage(url: video.thumbnail)
              .scaledToFill()
              .blur(radius: 18)
              .opacity(0.5)
            Image(systemName: "waveform")
              .font(.system(size: 26, weight: .medium))
              .foregroundStyle(.white)
          }
        } else if controller.state == .playing || controller.state == .paused {
          LiveVideoPreviewLayer(player: controller.player)
        } else {
          LiveRemoteImage(url: video.thumbnail)
            .scaledToFill()
        }

        // Tap surface below the controls: pressing play or close must not
        // expand the player.
        Color.clear
          .contentShape(Rectangle())
          .onTapGesture { onExpand() }
          .accessibilityIdentifier("live.miniplayer.open")

        HStack(spacing: 8) {
          Button(action: { controller.togglePlayback() }) {
            Image(systemName: controller.state == .playing ? "pause.fill" : "play.fill")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 34, height: 34)
              .background(.black.opacity(0.55), in: Circle())
          }
          .accessibilityLabel(controller.state == .playing ? "Pause" : "Play")
          .accessibilityIdentifier("live.miniplayer.playback")

          Button(action: { coordinator.close() }) {
            Image(systemName: "xmark")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 30, height: 30)
              .background(.black.opacity(0.55), in: Circle())
          }
          .accessibilityLabel("Close player")
          .accessibilityIdentifier("live.miniplayer.close")
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      }
      .frame(width: 240, height: 135)
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(.white.opacity(0.14), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
      .offset(y: dragTranslation)
      .opacity(dragOpacity)
      .gesture(miniPlayerDragGesture)
      .accessibilityElement(children: .contain)
      .accessibilityAction(named: "Expand player") {
        onExpand()
      }
      .accessibilityAction(named: "Close player") {
        coordinator.close()
      }
      .accessibilityIdentifier("live.miniplayer")
    }
  }

  private var dragOpacity: Double {
    let distance = abs(dragTranslation)
    guard distance > MiniPlayerDragGesture.activationDistance else {
      return 1
    }
    return max(
      0.35,
      1 - (distance - MiniPlayerDragGesture.activationDistance) / 180
    )
  }

  private var miniPlayerDragGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        let vertical = value.translation.height
        dragTranslation = abs(vertical) > abs(value.translation.width)
          ? vertical
          : 0
      }
      .onEnded { value in
        defer {
          withAnimation(.snappy(duration: 0.18)) {
            dragTranslation = 0
          }
        }

        switch MiniPlayerDragGesture.action(
          forTranslationHeight: value.translation.height
        ) {
        case .expand:
          onExpand()
        case .close:
          coordinator.close()
        case nil:
          break
        }
      }
  }
}

/// Renders the playing video in the mini player: the same AVPlayer can back
/// several layers, so the small preview shows live video while the full
/// surface is off screen. Audio-only keeps the poster instead.
private struct LiveVideoPreviewLayer: UIViewRepresentable {
  let player: AVPlayer

  func makeUIView(context: Context) -> PlayerPreviewView {
    PlayerPreviewView(player: player)
  }

  func updateUIView(_ uiView: PlayerPreviewView, context: Context) {}
}

private final class PlayerPreviewView: UIView {
  private let playerLayer = AVPlayerLayer()

  init(player: AVPlayer) {
    super.init(frame: .zero)
    backgroundColor = .clear
    playerLayer.player = player
    playerLayer.videoGravity = .resizeAspect
    layer.addSublayer(playerLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }
}
