import Foundation

enum LiveChannelSort: String, CaseIterable, Identifiable {
  case latest
  case popular
  case oldest

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .latest:
      return "Newest"
    case .popular:
      return "Popular"
    case .oldest:
      return "Oldest"
    }
  }
}

enum LiveChannelTab: String, CaseIterable, Identifiable {
  case videos
  case live
  case playlists
  case about

  var id: String {
    rawValue
  }

  var title: String {
    rawValue.prefix(1).uppercased() + rawValue.dropFirst()
  }
}

struct LiveChannelPage: Decodable, Equatable {
  let name: String
  let description: String
  let avatarURL: String
  let bannerURL: String
  let subscriberCount: Int64
  let isVerified: Bool
  let videos: [LiveVideoItem]
  let nextPage: String?

  var avatar: URL? {
    URL(string: avatarURL)
  }

  var banner: URL? {
    URL(string: bannerURL)
  }

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

struct LiveChannelPlaylistsPage: Decodable, Equatable {
  let playlists: [LivePlaylistResult]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case playlists
    case nextPage = "nextpage"
  }
}
