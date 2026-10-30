import AVFoundation
import SwiftUI

struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void
  let containerSize: CGSize
  let tabBarBand: CGFloat
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
        videoLayer(video, controller: controller)

        Color.clear
          .contentShape(Rectangle())
          .onTapGesture { onExpand() }
          .accessibilityIdentifier("live.miniplayer.open")

        controls(controller)
        .padding(12)
        // One rasterized layer: re-compositing glass on every drag frame stutters.
        .compositingGroup()
      }
      .frame(width: Self.cardWidth, height: Self.cardHeight)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(.white.opacity(0.14), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.3), radius: 12, y: 5)
      // Offset placement keeps the card and its buttons one piece while dragging.
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      .offset(clampedOffset)
      // simultaneousGesture: the drag works whatever child is under the finger.
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

  private var restingOffset: CGSize {
    CGSize(width: -Self.margin, height: -(tabBarBand + Self.margin))
  }

  private var minOffsetX: CGFloat {
    -(containerSize.width - Self.cardWidth - 2 * Self.margin)
  }

  private var clampedOffset: CGSize {
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
  @ViewBuilder
  func pipGlassBackground() -> some View {
    if #available(iOS 26.0, *) {
      self.glassEffect(.clear, in: Circle())
    } else {
      self.background(.ultraThinMaterial, in: Circle())
    }
  }
}
