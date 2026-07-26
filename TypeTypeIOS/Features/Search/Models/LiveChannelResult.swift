import Foundation

struct LiveChannelResult: Decodable, Hashable, Identifiable {
  let id: String
  let name: String
  let url: String
  let thumbnailURL: String
  let description: String
  let subscriberCount: Int64
  let streamCount: Int64
  let isVerified: Bool

  var canonicalID: String {
    url.isEmpty ? id : url
  }

  var thumbnail: URL? {
    URL(string: thumbnailURL)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case url
    case thumbnailURL = "thumbnailUrl"
    case description
    case subscriberCount
    case streamCount
    case isVerified
  }
}
