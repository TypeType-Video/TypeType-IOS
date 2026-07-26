import ImageIO
import SwiftUI
import UIKit

struct DemoAnimatedImageView: UIViewRepresentable {
  let data: Data

  func makeUIView(context: Context) -> UIImageView {
    let view = UIImageView()
    view.clipsToBounds = true
    view.contentMode = .scaleAspectFill
    return view
  }

  func updateUIView(_ view: UIImageView, context: Context) {
    guard context.coordinator.renderedData != data else { return }
    context.coordinator.renderedData = data
    view.image = Self.animatedImage(from: data)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  final class Coordinator {
    var renderedData: Data?
  }

  static func decodedFrameCount(in data: Data) -> Int {
    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil)
    else {
      return 0
    }
    return CGImageSourceGetCount(source)
  }

  private static func animatedImage(from data: Data) -> UIImage? {
    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil)
    else {
      return UIImage(data: data)
    }
    let frameCount = decodedFrameCount(in: data)
    guard frameCount > 1 else {
      guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return UIImage(data: data)
      }
      return UIImage(cgImage: image)
    }

    var frames: [UIImage] = []
    var duration = 0.0
    for index in 0..<frameCount {
      guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else {
        continue
      }
      frames.append(UIImage(cgImage: frame))
      duration += frameDuration(source: source, index: index)
    }
    guard !frames.isEmpty else { return UIImage(data: data) }
    return UIImage.animatedImage(
      with: frames,
      duration: max(duration, Double(frames.count) * 0.06)
    )
  }

  private static func frameDuration(
    source: CGImageSource,
    index: Int
  ) -> Double {
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(
        source,
        index,
        nil
      ) as? [CFString: Any],
      let gif = properties[kCGImagePropertyGIFDictionary]
        as? [CFString: Any]
    else {
      return 0.1
    }
    let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double
    let clamped = gif[kCGImagePropertyGIFDelayTime] as? Double
    return max(0.02, unclamped ?? clamped ?? 0.1)
  }
}
