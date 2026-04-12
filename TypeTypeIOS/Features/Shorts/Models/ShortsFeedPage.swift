import Foundation

struct ShortsFeedPage: Decodable {
  let videos: [HomeVideoItem]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case videos
    case nextPage = "nextpage"
  }
}
