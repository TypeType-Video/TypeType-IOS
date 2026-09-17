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
    case .subscriptions: return String(localized: "Subscriptions")
    case .history: return String(localized: "History")
    case .playlists: return String(localized: "Playlists")
    case .watchLater: return String(localized: "Watch later")
    case .favorites: return String(localized: "Favorites")
    case .progress: return String(localized: "Playback progress")
    case .searchHistory: return String(localized: "Search history")
    case .savedPlaylists: return String(localized: "Saved playlists")
    case .settings: return String(localized: "Settings")
    case .contentFilters: return String(localized: "Content filters")
    }
  }
}

struct LiveTypeTypeRestoreSummary: Decodable, Equatable {
  let restored: [String: Int]

  var total: Int {
    restored.values.reduce(0, +)
  }
}
