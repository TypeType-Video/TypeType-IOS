import ImageIO
import UIKit

actor LiveSeekbarIconLoader {
  static let shared = LiveSeekbarIconLoader()

  private var images: [URL: UIImage] = [:]
  private var running: [URL: Task<UIImage?, Never>] = [:]
  private let session: URLSession
  private static let maxPixels: CGFloat = 160
  private static let maxFrames = 240

  init(session: URLSession = .shared) {
    self.session = session
  }

  func image(for url: URL) async -> UIImage? {
    if let image = images[url] { return image }
    if let task = running[url] { return await task.value }
    let session = session
    let task = Task.detached(priority: .utility) { () -> UIImage? in
      guard let (data, response) = try? await session.data(from: url),
        (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true
      else { return nil }
      return Self.decode(data)
    }
    running[url] = task
    let image = await task.value
    running[url] = nil
    if let image { images[url] = image }
    return image
  }

  nonisolated static func decode(_ data: Data, maxPixels: CGFloat = maxPixels) -> UIImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
    else { return nil }
    let options = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixels,
    ] as CFDictionary
    let count = min(CGImageSourceGetCount(source), maxFrames)
    guard count > 1 else {
      return CGImageSourceCreateThumbnailAtIndex(source, 0, options).map { UIImage(cgImage: $0) }
    }
    var frames: [UIImage] = []
    var duration: TimeInterval = 0
    for index in 0..<count {
      guard let frame = CGImageSourceCreateThumbnailAtIndex(source, index, options) else { continue }
      frames.append(UIImage(cgImage: frame))
      duration += delay(source, index)
    }
    guard frames.count > 1 else { return frames.first }
    return UIImage.animatedImage(with: frames, duration: duration)
  }

  // Browsers play delays under 20 ms at 100 ms; GIFs saved with 0 rely on it.
  private nonisolated static func delay(_ source: CGImageSource, _ index: Int) -> TimeInterval {
    let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
    let containers = [kCGImagePropertyGIFDictionary, kCGImagePropertyPNGDictionary, kCGImagePropertyWebPDictionary]
    let keys = [
      kCGImagePropertyGIFUnclampedDelayTime, kCGImagePropertyGIFDelayTime,
      kCGImagePropertyAPNGUnclampedDelayTime, kCGImagePropertyAPNGDelayTime,
      kCGImagePropertyWebPUnclampedDelayTime, kCGImagePropertyWebPDelayTime,
    ]
    for container in containers {
      guard let values = properties?[container] as? [CFString: Any] else { continue }
      for key in keys {
        if let value = values[key] as? Double, value > 0 { return value < 0.02 ? 0.1 : value }
      }
    }
    return 0.1
  }
}
