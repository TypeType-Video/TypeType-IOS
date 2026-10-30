import SwiftUI

struct LiveRemoteImage: View {
  @Environment(\.themePalette) private var palette
  let url: URL?
  let contentMode: ContentMode
  @State private var loaded: Loaded?
  @State private var failedURL: URL?
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
        if let image = shownImage(pixels) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .transition(.opacity)
        } else if url == nil || failedURL == url {
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

  private struct Loaded {
    let url: URL?
    let image: UIImage
  }

  // Never another URL's picture: a reused view would show the previous channel until the new one arrives.
  private func shownImage(_ pixels: CGFloat) -> UIImage? {
    if let loaded, loaded.url == url { return loaded.image }
    return cached(pixels)
  }

  private func cached(_ pixels: CGFloat) -> UIImage? {
    guard let url = LiveImageURLResolver.resolve(url), pixels > 0 else { return nil }
    return pipeline.cachedImage(for: url, maxPixelSize: pixels)
  }

  // A layout change (an expanding description) resizes the view and restarts this task: a zero size is not a
  // failure, and a superseded load must not overwrite what a newer one showed.
  private func load(_ pixels: CGFloat) async {
    let requested = url
    guard pixels > 0 else { return }
    guard let resolved = LiveImageURLResolver.resolve(requested) else {
      failedURL = requested
      return
    }
    if cached(pixels) != nil { return }
    let image = await pipeline.image(for: resolved, maxPixelSize: pixels)
    guard !Task.isCancelled, requested == url else { return }
    withAnimation(.easeOut(duration: 0.15)) {
      if let image {
        loaded = Loaded(url: requested, image: image)
        failedURL = nil
      } else if loaded?.url != requested {
        failedURL = requested
      }
    }
  }
}
