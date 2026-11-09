import Foundation
import ImageIO
import UniformTypeIdentifiers

enum LiveSeekbarIconPayload: Equatable {
  case ready(Data, mediaType: String)
  case unsupported
  case tooLarge

  static let maxBytes = 2 * 1_024 * 1_024
  private static let resizedPixels = 256

  static func make(from data: Data, maxBytes: Int = maxBytes) -> Self {
    let mediaType = mediaType(of: data)
    if let mediaType, data.count <= maxBytes { return .ready(data, mediaType: mediaType) }
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      CGImageSourceGetCount(source) > 0
    else { return .unsupported }
    if CGImageSourceGetCount(source) > 1 { return .tooLarge }
    guard let png = resizedPNG(source) else { return .unsupported }
    return png.count <= maxBytes ? .ready(png, mediaType: "image/png") : .tooLarge
  }

  static func mediaType(of data: Data) -> String? {
    let bytes = [UInt8](data.prefix(12))
    if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
    if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
    if bytes.starts(with: Array("GIF8".utf8)) { return "image/gif" }
    if bytes.count == 12, bytes.starts(with: Array("RIFF".utf8)), Array(bytes[8..<12]) == Array("WEBP".utf8) {
      return "image/webp"
    }
    return nil
  }

  private static func resizedPNG(_ source: CGImageSource) -> Data? {
    let options = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: resizedPixels,
    ] as CFDictionary
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil)
    else { return nil }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination) ? output as Data : nil
  }
}
