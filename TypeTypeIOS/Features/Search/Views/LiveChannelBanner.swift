import SwiftUI

struct LiveChannelBanner: View {
  static let aspectRatio: CGFloat = 16 / 6
  @Environment(\.themePalette) private var palette
  let url: URL?

  var body: some View {
    GeometryReader { proxy in
      // At rest the banner starts below the bar: the gap above it is filled by stretching, so the picture runs
      // behind the bar and keeps growing when the page is pulled down.
      let stretch = max(proxy.frame(in: .scrollView).minY, 0)
      LiveRemoteImage(url: url)
        .frame(width: proxy.size.width, height: proxy.size.height + stretch)
        .overlay {
          LinearGradient(
            stops: [
              .init(color: .black.opacity(0.45), location: 0),
              .init(color: .clear, location: 0.35),
              .init(color: .clear, location: 0.6),
              .init(color: palette.background, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        }
        .offset(y: -stretch)
    }
    .aspectRatio(Self.aspectRatio, contentMode: .fit)
    .accessibilityHidden(true)
  }
}
