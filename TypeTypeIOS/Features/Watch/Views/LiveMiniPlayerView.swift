import AVFoundation
import SwiftUI

/// Picture-in-picture style mini player: a compact, freely movable video
/// card with system-PiP-like controls. It is clamped to the area above the
/// tab bar so it never collides with navigation or menus.
struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void
  let containerSize: CGSize
  let bottomInset: CGFloat

  @State private var dragOffset: CGSize = .zero
  @State private var dragStart: CGSize = .zero
  @State private var isDragging = false
  @State private var isScrubbing = false
  @State private var scrubValue: Double = 0

  private static let cardWidth: CGFloat = 260
  private static let cardHeight: CGFloat = 146
  private static let margin: CGFloat = 12
  /// The tab bar band: home-indicator inset plus the bar itself. The card
  /// may never enter it.
  private var tabBarBand: CGFloat { bottomInset + 49 }

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

        Color.clear
          .contentShape(Rectangle())
          .onTapGesture { onExpand() }
          .accessibilityIdentifier("live.miniplayer.open")

        VStack(spacing: 0) {
          HStack {
            controlButton(
              systemName: "xmark",
              label: "Close player",
              identifier: "live.miniplayer.close",
              diameter: 36
            ) {
              coordinator.close()
            }
            Spacer()
            controlButton(
              systemName: "arrow.up.left.and.arrow.down.right",
              label: "Expand player",
              identifier: "live.miniplayer.expand",
              diameter: 36
            ) {
              onExpand()
            }
          }

          Spacer()

          HStack(spacing: 18) {
            controlButton(
              systemName: "gobackward.10",
              label: "Seek backward 10 seconds",
              identifier: "live.miniplayer.rewind",
              diameter: 48
            ) {
              controller.seek(to: controller.position - 10)
            }
            controlButton(
              systemName: controller.state == .playing ? "pause.fill" : "play.fill",
              label: controller.state == .playing ? "Pause" : "Play",
              identifier: "live.miniplayer.playback",
              diameter: 64
            ) {
              controller.togglePlayback()
            }
            controlButton(
              systemName: "goforward.10",
              label: "Seek forward 10 seconds",
              identifier: "live.miniplayer.forward",
              diameter: 48
            ) {
              controller.seek(to: controller.position + 10)
            }
          }
          .frame(maxWidth: .infinity)

          Spacer()

          scrubber(controller: controller)
        }
        .padding(12)
      }
      .frame(width: Self.cardWidth, height: Self.cardHeight)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(.white.opacity(0.14), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.3), radius: 12, y: 5)
      .position(clampedPosition)
      .gesture(freeDrag)
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

  private func controlButton(
    systemName: String,
    label: String,
    identifier: String,
    diameter: CGFloat,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: diameter * 0.38, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: diameter, height: diameter)
        .background(.ultraThinMaterial, in: Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityIdentifier(identifier)
  }

  private func scrubber(controller: LivePlayerController) -> some View {
    Slider(
      value: Binding(
        get: { isScrubbing ? scrubValue : controller.position },
        set: { scrubValue = $0 }
      ),
      in: 0...max(controller.duration, 1)
    ) { editing in
      isScrubbing = editing
      if !editing {
        controller.seek(to: scrubValue)
      }
    }
    .tint(.white)
  }

  // MARK: - Free movement

  private var clampedPosition: CGPoint {
    let halfW = Self.cardWidth / 2
    let halfH = Self.cardHeight / 2
    let baseX = containerSize.width - halfW - Self.margin
    let baseY = containerSize.height - tabBarBand - halfH - Self.margin
    let x = min(
      max(baseX + dragOffset.width, halfW + Self.margin),
      containerSize.width - halfW - Self.margin
    )
    let y = min(
      max(baseY + dragOffset.height, halfH + Self.margin),
      containerSize.height - tabBarBand - halfH - Self.margin
    )
    return CGPoint(x: x, y: y)
  }

  private var freeDrag: some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged { value in
        if !isDragging {
          dragStart = dragOffset
          isDragging = true
        }
        dragOffset = CGSize(
          width: dragStart.width + value.translation.width,
          height: dragStart.height + value.translation.height
        )
      }
      .onEnded { _ in
        isDragging = false
        dragStart = dragOffset
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
