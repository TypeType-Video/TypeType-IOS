import CoreGraphics
import Foundation

struct LiveEndScreenElement: Decodable, Equatable, Identifiable {
  enum Kind: String {
    case video, playlist, channel, website
  }

  let id: String
  let kind: Kind?
  let title: String
  let url: String
  let thumbnailURL: String
  let start: TimeInterval
  let end: TimeInterval
  let left: Double
  let top: Double
  let width: Double
  let aspectRatio: Double

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
    kind = Kind(rawValue: try values.decodeIfPresent(String.self, forKey: .type) ?? "")
    title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
    url = try values.decodeIfPresent(String.self, forKey: .url) ?? ""
    thumbnailURL = try values.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    start = TimeInterval(try values.decodeIfPresent(Int64.self, forKey: .startMs) ?? 0) / 1_000
    end = TimeInterval(try values.decodeIfPresent(Int64.self, forKey: .endMs) ?? 0) / 1_000
    left = try values.decodeIfPresent(Double.self, forKey: .left) ?? 0
    top = try values.decodeIfPresent(Double.self, forKey: .top) ?? 0
    width = try values.decodeIfPresent(Double.self, forKey: .width) ?? 0
    aspectRatio = try values.decodeIfPresent(Double.self, forKey: .aspectRatio) ?? 0
  }

  var isUsable: Bool {
    kind != nil && !id.isEmpty && !url.isEmpty && end > start
      && (0..<1).contains(left) && (0..<1).contains(top) && width > 0 && aspectRatio > 0
  }

  func isVisible(at time: TimeInterval) -> Bool {
    time >= start && time < end
  }

  func box(in frame: CGRect) -> CGRect {
    guard frame.height > 0 else { return .zero }
    let boxWidth = min(width, 1 - left)
    let boxHeight = min(boxWidth * (frame.width / frame.height) / aspectRatio, 1 - top)
    return CGRect(
      x: frame.minX + left * frame.width,
      y: frame.minY + top * frame.height,
      width: boxWidth * frame.width,
      height: boxHeight * frame.height
    )
  }

  static func videoFrame(in container: CGSize, videoAspectRatio: CGFloat) -> CGRect {
    guard container.width > 0, container.height > 0, videoAspectRatio > 0 else {
      return CGRect(origin: .zero, size: container)
    }
    let width = min(container.width, container.height * videoAspectRatio)
    let height = width / videoAspectRatio
    return CGRect(x: (container.width - width) / 2, y: (container.height - height) / 2, width: width, height: height)
  }

  private enum CodingKeys: String, CodingKey {
    case id, type, title, url, startMs, endMs, left, top, width, aspectRatio
    case thumbnailURL = "thumbnailUrl"
  }
}
