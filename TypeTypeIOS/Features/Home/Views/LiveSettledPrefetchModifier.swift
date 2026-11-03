import SwiftUI

private struct LiveCardVisibility: Equatable {
  let fraction: Double
  let top: Double

  // Rounded: a scroll moves every card each frame, and the prefetch only needs to know which one rests in view.
  init(_ proxy: GeometryProxy) {
    let card = CGRect(origin: .zero, size: proxy.size)
    let area = card.width * card.height
    guard area > 0, let viewport = proxy.bounds(of: .scrollView) else {
      fraction = 0
      top = 0
      return
    }
    let visible = card.intersection(viewport)
    let exact = visible.isNull ? 0 : visible.width * visible.height / area
    fraction = (exact * 10).rounded() / 10
    top = (proxy.frame(in: .scrollView).minY / 16).rounded() * 16
  }
}

private struct LiveSettledPrefetchModifier: ViewModifier {
  @Environment(\.liveSettledPrefetch) private var prefetch
  @State private var id = UUID()
  let video: LiveVideoItem

  func body(content: Content) -> some View {
    if let prefetch {
      content
        .onGeometryChange(for: LiveCardVisibility.self, of: LiveCardVisibility.init) { visibility in
          prefetch.place(id, video: video, visibleFraction: visibility.fraction, top: visibility.top)
        }
        .onDisappear { prefetch.remove(id) }
    } else {
      content
    }
  }
}

extension View {
  func liveSettledPrefetch(_ video: LiveVideoItem) -> some View {
    modifier(LiveSettledPrefetchModifier(video: video))
  }
}
