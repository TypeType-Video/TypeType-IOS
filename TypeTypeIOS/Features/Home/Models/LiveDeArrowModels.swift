import Foundation

struct LiveDeArrowItem: Decodable, Equatable {
  let videoID: String
  let title: String?
  let thumbnailURL: String?
  let titles: [LiveDeArrowTitleCandidate]
  let thumbnails: [LiveDeArrowThumbnailCandidate]
  let randomTime: Double?
  let videoDuration: Double?
  let attributionURL: String

  private enum CodingKeys: String, CodingKey {
    case videoID = "videoId"
    case title
    case thumbnailURL = "thumbnailUrl"
    case titles, thumbnails, randomTime, videoDuration
    case attributionURL = "attributionUrl"
  }
}

struct LiveDeArrowTitleCandidate: Decodable, Equatable {
  let title: String
  let original: Bool
  let votes: Int
  let locked: Bool
  let uuid: String
}

struct LiveDeArrowThumbnailCandidate: Decodable, Equatable {
  let timestamp: Double?
  let thumbnailURL: String?
  let original: Bool
  let votes: Int
  let locked: Bool
  let uuid: String

  private enum CodingKeys: String, CodingKey {
    case timestamp
    case thumbnailURL = "thumbnailUrl"
    case original, votes, locked, uuid
  }
}

struct LiveVideoBranding: Equatable {
  let title: String
  let thumbnailURL: URL?
}
