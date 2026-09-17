import Foundation

enum LiveTypeTypeBackupCategory: String, CaseIterable, Identifiable {
  case subscriptions
  case history
  case playlists
  case watchLater = "watchLater"
  case favorites
  case progress
  case searchHistory = "searchHistory"
  case savedPlaylists = "savedPlaylists"
  case settings
  case contentFilters = "contentFilters"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .subscriptions: return "Subscriptions"
    case .history: return "History"
    case .playlists: return "Playlists"
    case .watchLater: return "Watch later"
    case .favorites: return "Favorites"
    case .progress: return "Playback progress"
    case .searchHistory: return "Search history"
    case .savedPlaylists: return "Saved playlists"
    case .settings: return "Settings"
    case .contentFilters: return "Content filters"
    }
  }
}

struct LiveTypeTypeRestoreSummary: Decodable, Equatable {
  let restored: [String: Int]

  var total: Int {
    restored.values.reduce(0, +)
  }
}
