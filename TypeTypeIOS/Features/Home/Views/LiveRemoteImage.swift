import SwiftUI

/// Remote image through the shared pipeline: cached, deduplicated, downsampled
/// to the displayed size, with a skeleton while it loads.
struct LiveRemoteImage: View {
  @Environment(\.themePalette) private var palette
  let url: URL?
  let contentMode: ContentMode
  @State private var image: UIImage?
  @State private var failed = false
  @Environment(\.displayScale) private var displayScale
  @Environment(\.imagePipeline) private var pipeline

  init(url: URL?, contentMode: ContentMode = .fill) {
    self.url = url
    self.contentMode = contentMode
  }

  var body: some View {
    GeometryReader { proxy in
      let pixels = max(proxy.size.width, proxy.size.height) * displayScale
      ZStack {
        if let image = image ?? cached(pixels) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .transition(.opacity)
        } else if failed || url == nil {
          Rectangle().fill(palette.groupedSurface)
        } else {
          TypeTypeSkeleton()
        }
      }
      .task(id: LoadKey(url: url, pixels: pixels)) {
        await load(pixels)
      }
    }
  }

  private struct LoadKey: Hashable {
    let url: URL?
    let pixels: CGFloat
  }

  private func cached(_ pixels: CGFloat) -> UIImage? {
    guard let url = LiveImageURLResolver.resolve(url), pixels > 0 else { return nil }
    return pipeline.cachedImage(for: url, maxPixelSize: pixels)
  }

  private func load(_ pixels: CGFloat) async {
    guard let url = LiveImageURLResolver.resolve(url), pixels > 0 else {
      failed = true
      return
    }
    if cached(pixels) != nil { return }
    let loaded = await pipeline.image(for: url, maxPixelSize: pixels)
    withAnimation(.easeOut(duration: 0.15)) {
      image = loaded
      failed = loaded == nil
    }
  }
}
