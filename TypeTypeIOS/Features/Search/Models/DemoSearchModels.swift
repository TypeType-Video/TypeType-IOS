import Foundation

enum DemoSearchScope: String, CaseIterable, Identifiable {
  case all = "All"
  case videos = "Videos"
  case channels = "Channels"
  case playlists = "Playlists"

  var id: String { rawValue }

  var systemImage: String {
    switch self {
    case .all: return "square.grid.2x2"
    case .videos: return "play.rectangle"
    case .channels: return "person.2"
    case .playlists: return "rectangle.stack.badge.play"
    }
  }
}

enum DemoSearchService: String, CaseIterable, Identifiable {
  case youtube = "YouTube"
  case nicoNico = "NicoNico"
  case biliBili = "BiliBili"

  var id: String { rawValue }
}

enum DemoSearchContentFilter: String, CaseIterable, Identifiable {
  case all = "All content"
  case videos = "Videos"
  case live = "Live"
  case music = "Music songs"
  case musicVideos = "Music videos"
  case albums = "Albums"
  case musicPlaylists = "Music playlists"
  case artists = "Artists"
  case series = "Series"

  var id: String { rawValue }
}

enum DemoSearchSort: String, CaseIterable, Identifiable {
  case relevance = "Relevance"
  case newest = "Newest"
  case views = "Most viewed"

  var id: String { rawValue }
}

struct DemoSearchChannel: Identifiable, Hashable {
  let id: String
  let name: String
  let handle: String
  let followers: String
  let artwork: DemoArtwork
  let summary: String
  let isVerified: Bool
  let isFollowing: Bool
}
