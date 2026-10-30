import SwiftUI

struct LivePlayerSponsorSegmentBands: View {
  @ObservedObject var controller: LivePlayerController

  var body: some View {
    GeometryReader { proxy in
      ForEach(controller.visibleSponsorBlockWindows) { window in
        let band = bandSpan(window, width: proxy.size.width)
        Capsule()
          .fill(LiveSponsorBlockPalette.color(for: window.segment.category).opacity(0.55))
          .frame(width: band.width, height: 5)
          .position(x: band.center, y: proxy.size.height / 2)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func bandSpan(_ window: LiveSponsorBlockWindow, width: CGFloat) -> (width: CGFloat, center: CGFloat) {
    let span: Double = max(controller.duration, 1)
    let start: Double = min(max(window.start / span, 0), 1)
    let end: Double = min(max(window.end / span, 0), 1)
    return (max(width * CGFloat(end - start), 3), width * CGFloat(start + end) / 2)
  }
}
