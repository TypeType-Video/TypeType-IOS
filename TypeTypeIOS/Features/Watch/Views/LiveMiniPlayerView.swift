import AVFoundation
import SwiftUI

/// Picture-in-picture style mini player: a compact, freely movable video
/// card that snaps to the nearest edge like the system PiP window. The
/// card moves as one piece (offset-based placement), and it is clamped
/// above the tab bar so it can never collide with navigation or menus.
struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void
  let containerSize: CGSize
  let tabBarBand: CGFloat

  @State private var dragOffset: CGSize = .zero
  @State private var dragStart: CGSize = .zero
  @State private var isDragging = false

  private static let cardWidth: CGFloat = 260
  private static let cardHeight: CGFloat = 146
  private static let margin: CGFloat = 12

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
            glassButton(
              systemName: "xmark",
              label: "Close player",
              identifier: "live.miniplayer.close",
              diameter: 36
            ) {
              coordinator.close()
            }
            Spacer()
            glassButton(
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
            glassButton(
              systemName: "gobackward.10",
              label: "Seek backward 10 seconds",
              identifier: "live.miniplayer.rewind",
              diameter: 48
            ) {
              controller.seek(to: controller.position - 10)
            }
            glassButton(
              systemName: controller.state == .playing ? "pause.fill" : "play.fill",
              label: controller.state == .playing ? "Pause" : "Play",
              identifier: "live.miniplayer.playback",
              diameter: 64
            ) {
              controller.togglePlayback()
            }
            glassButton(
              systemName: "goforward.10",
              label: "Seek forward 10 seconds",
              identifier: "live.miniplayer.forward",
              diameter: 48
            ) {
              controller.seek(to: controller.position + 10)
            }
          }
          .frame(maxWidth: .infinity)
        }
        .padding(12)
        // One rasterized layer while dragging: re-compositing glass and
        // shadows every drag frame is what made the movement stutter.
        .compositingGroup()
      }
      .frame(width: Self.cardWidth, height: Self.cardHeight)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(.white.opacity(0.14), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.3), radius: 12, y: 5)
      // Offset-based placement keeps the card and its controls one atomic
      // piece; absolute positioning let the buttons detach while dragging.
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      .offset(x: clampedOffset.width, y: clampedOffset.height)
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

  private func glassButton(
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
        .pipGlassBackground()
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityIdentifier(identifier)
  }

  // MARK: - Free movement with edge snapping

  private var baseX: CGFloat {
    containerSize.width - Self.cardWidth / 2 - Self.margin
  }

  private var baseY: CGFloat {
    containerSize.height - tabBarBand - Self.cardHeight / 2 - Self.margin
  }



  private var clampedOffset: CGSize {
    let minX = -(containerSize.width - Self.cardWidth - 2 * Self.margin)
    let minY = -(baseY - Self.cardHeight / 2 - Self.margin)
    return CGSize(
      width: min(max(dragOffset.width, minX), 0),
      height: min(max(dragOffset.height, minY), 0)
    )
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
        // Snap to the nearest edge like the system PiP window.
        withAnimation(.snappy(duration: 0.22)) {
          let leftEdge = -(containerSize.width - Self.cardWidth - 2 * Self.margin)
          dragOffset.width = abs(dragOffset.width - leftEdge / 2) > abs(leftEdge) / 2
            ? 0
            : leftEdge
          dragStart = dragOffset
        }
      }
  }
}

private extension View {
  /// Liquid-Glass look on iOS 26 and later, translucent material below.
  @ViewBuilder
  func pipGlassBackground() -> some View {
    if #available(iOS 26.0, *) {
      // Thin glass is more transparent; like all system glass it also
      // follows the global "Reduce Transparency" accessibility setting.
      self.glassEffect(.thin, in: Circle())
    } else {
      self.background(.ultraThinMaterial, in: Circle())
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
