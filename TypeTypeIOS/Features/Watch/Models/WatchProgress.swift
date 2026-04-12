import Foundation

struct WatchProgress: Decodable {
  let videoURL: String
  let position: Int64
  let updatedAt: Int64

  private enum CodingKeys: String, CodingKey {
    case videoURL = "videoUrl"
    case position
    case updatedAt
  }
}
