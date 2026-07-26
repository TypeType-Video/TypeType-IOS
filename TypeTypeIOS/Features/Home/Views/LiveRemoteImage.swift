import SwiftUI

struct LiveRemoteImage: View {
  let url: URL?
  let contentMode: ContentMode

  init(
    url: URL?,
    contentMode: ContentMode = .fill
  ) {
    self.url = url
    self.contentMode = contentMode
  }

  var body: some View {
    AsyncImage(url: url) { phase in
      switch phase {
      case let .success(image):
        image
          .resizable()
          .aspectRatio(contentMode: contentMode)
      case .failure:
        placeholder
      case .empty:
        placeholder
      @unknown default:
        placeholder
      }
    }
  }

  private var placeholder: some View {
    ZStack {
      LinearGradient(
        colors: [
          DemoTheme.surface,
          DemoTheme.elevatedSurface,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      Image(systemName: "play.rectangle")
        .font(.title2)
        .foregroundStyle(.tertiary)
    }
  }
}
