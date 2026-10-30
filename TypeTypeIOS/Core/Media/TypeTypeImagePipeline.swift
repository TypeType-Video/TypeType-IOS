import SwiftUI
import ImageIO
import UIKit

actor TypeTypeImagePipeline {
  private nonisolated let memory = ImageMemoryCache()
  private var inFlight: [String: Task<UIImage?, Never>] = [:]
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  nonisolated func cachedImage(for url: URL, maxPixelSize: CGFloat) -> UIImage? {
    memory.image(for: Self.key(url, maxPixelSize))
  }

  func image(for url: URL, maxPixelSize: CGFloat) async -> UIImage? {
    let key = Self.key(url, maxPixelSize)
    if let cached = memory.image(for: key) { return cached }
    if let running = inFlight[key] { return await running.value }
    let session = session
    // Utility priority: image fetches must never compete with media.
    let task = Task.detached(priority: .utility) {
      await Self.load(url, maxPixelSize: Self.bucket(maxPixelSize), session: session)
    }
    inFlight[key] = task
    let image = await task.value
    inFlight[key] = nil
    if let image {
      memory.store(image, for: key, cost: Self.cost(of: image))
    }
    return image
  }

  private static func bucket(_ size: CGFloat) -> CGFloat {
    for limit: CGFloat in [160, 320, 640, 960, 1_280] where size <= limit { return limit }
    return 1_920
  }

  private static func key(_ url: URL, _ size: CGFloat) -> String {
    "\(Int(bucket(size)))|\(url.absoluteString)"
  }

  private static func cost(of image: UIImage) -> Int {
    guard let cgImage = image.cgImage else { return 1 }
    return cgImage.bytesPerRow * cgImage.height
  }

  private static func load(_ url: URL, maxPixelSize: CGFloat, session: URLSession) async -> UIImage? {
    for attempt in 0..<3 {
      if attempt > 0 {
        try? await Task.sleep(for: .milliseconds(attempt == 1 ? 400 : 1_200))
      }
      guard let (data, response) = try? await session.data(from: url) else { continue }
      if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        if http.statusCode == 404 { return nil }
        continue
      }
      if let image = downsample(data, maxPixelSize: maxPixelSize) { return image }
    }
    return nil
  }

  private static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
    let options = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ] as CFDictionary
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
    return UIImage(cgImage: image)
  }
}

// NSCache is thread-safe; this wrapper states it to Swift.
private final class ImageMemoryCache: @unchecked Sendable {
  private let storage: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.totalCostLimit = 96 * 1_024 * 1_024
    return cache
  }()

  func image(for key: String) -> UIImage? {
    storage.object(forKey: key as NSString)
  }

  func store(_ image: UIImage, for key: String, cost: Int) {
    storage.setObject(image, forKey: key as NSString, cost: cost)
  }
}

private struct TypeTypeImagePipelineKey: EnvironmentKey {
  static let defaultValue = TypeTypeImagePipeline()
}

extension EnvironmentValues {
  var imagePipeline: TypeTypeImagePipeline {
    get { self[TypeTypeImagePipelineKey.self] }
    set { self[TypeTypeImagePipelineKey.self] = newValue }
  }
}
