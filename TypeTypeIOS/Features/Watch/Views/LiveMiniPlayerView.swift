import AVFoundation
import SwiftUI

/// Picture-in-picture style mini player: a compact, freely movable video
/// card that snaps to the nearest edge like the system PiP window. The card
/// moves as one piece and is clamped above the tab bar at all times.
struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void
  let containerSize: CGSize
  /// Distance from the container's bottom edge up to the tab bar top; the
  /// card may never enter this band.
  let tabBarBand: CGFloat
  /// Distance from the container's top edge down past the status bar /
  /// Dynamic Island; the card may never enter this band either.
  let topBand: CGFloat

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
            // No .scaledToFill on LiveRemoteImage (see the watch-page
            // player): the fill wrapper inflates the card and clipped the
            // close/expand row out of reach.
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
            MiniPlayPauseButton(controller: controller, diameter: 64)
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
        // One rasterized layer: re-compositing glass every drag frame is
        // what made the movement stutter.
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
      .offset(clampedOffset)
      // simultaneousGesture: the drag must work no matter which child
      // (tap surface, buttons) is under the finger.
      .simultaneousGesture(freeDrag)
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

  /// Offset from the flush bottom-trailing placement to the resting slot
  /// (bottom trailing, inside the margins, above the tab bar band).
  private var restingOffset: CGSize {
    CGSize(width: -Self.margin, height: -(tabBarBand + Self.margin))
  }

  private var minOffsetX: CGFloat {
    -(containerSize.width - Self.cardWidth - 2 * Self.margin)
  }

  private var clampedOffset: CGSize {
    // Total offset from the flush corner; the card stays inside the margins,
    // below the top band and above the tab bar band at all times.
    let minOffsetY = -(containerSize.height - Self.cardHeight - topBand - Self.margin)
    let maxOffsetY = -(tabBarBand + Self.margin)
    return CGSize(
      width: min(max(restingOffset.width + dragOffset.width, minOffsetX), 0),
      height: min(max(restingOffset.height + dragOffset.height, minOffsetY), maxOffsetY)
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
        // Snap to the nearest horizontal edge like the system PiP window;
        // the vertical position is kept.
        withAnimation(.snappy(duration: 0.22)) {
          let totalX = restingOffset.width + dragOffset.width
          let midX = minOffsetX / 2
          let snappedTotalX = totalX > midX ? 0 : minOffsetX
          dragOffset.width = snappedTotalX - restingOffset.width
          dragStart = dragOffset
        }
      }
  }
}

extension View {
  /// Liquid-Glass look on iOS 26 and later, translucent material below.
  @ViewBuilder
  func pipGlassBackground() -> some View {
    if #available(iOS 26.0, *) {
      // Clear glass is the most transparent system glass; like all system
      // glass it also follows the global "Reduce Transparency" setting.
      self.glassEffect(.clear, in: Circle())
    } else {
      self.background(.ultraThinMaterial, in: Circle())
    }
  }
}
