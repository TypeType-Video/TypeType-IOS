import Foundation

struct ChannelPage: Decodable {
  let name: String
  let description: String
  let avatarURL: String
  let bannerURL: String
  let subscriberCount: Int64
  let isVerified: Bool
  let videos: [HomeVideoItem]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case name
    case description
    case avatarURL = "avatarUrl"
    case bannerURL = "bannerUrl"
    case subscriberCount
    case isVerified
    case videos
    case nextPage = "nextpage"
  }
}
