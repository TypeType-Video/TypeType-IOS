import Foundation

enum LiveSettingsPage: String, Hashable, Identifiable {
  case accounts
  case appearance
  case player
  case notifications
  case content
  case algorithm
  case focus
  case rss
  case downloads
  case data
  case privacy
  case blocked
  case api
  case diagnostics
  case about

  var id: String { rawValue }

  static let groups: [[LiveSettingsPage]] = [
    [.player, .downloads],
    [.content, .algorithm, .focus, .blocked, .notifications],
    [.appearance],
    [.privacy, .data, .rss, .api],
    [.diagnostics, .about],
  ]

  static let groupTitles: [String?] = ["Watching", "What you see", "Look and feel", "Your data", "Help"]

  var title: String {
    switch self {
    case .accounts: "Instances and accounts"
    case .appearance: "Appearance"
    case .player: "Player"
    case .notifications: "Push notifications"
    case .content: "Content"
    case .algorithm: "Algorithm"
    case .focus: "Focus"
    case .rss: "Private RSS feeds"
    case .downloads: "Downloads"
    case .data: "Data and backups"
    case .privacy: "Privacy"
    case .blocked: "Blocked"
    case .api: "API"
    case .diagnostics: "Diagnostics"
    case .about: "About"
    }
  }

  var subtitle: String {
    switch self {
    case .accounts: "Instances, accounts and YouTube sign-in"
    case .appearance: "Theme, color and font"
    case .player: "Playback, gestures, languages, SponsorBlock"
    case .notifications: "Channels that alert you"
    case .content: "Home page, DeArrow, hidden sections"
    case .algorithm: "How the home page is built"
    case .focus: "Fade the channels that distract you"
    case .rss: "Private links to your feeds"
    case .downloads: "Videos saved for offline viewing"
    case .data: "Import and export your data"
    case .privacy: "Watch history and stored activity"
    case .blocked: "Hidden channels, videos and keywords"
    case .api: "Create and revoke keys for external apps."
    case .diagnostics: "Recent requests, for troubleshooting"
    case .about: "Versions and license"
    }
  }

  var icon: String {
    switch self {
    case .accounts: "person.crop.circle"
    case .appearance: "paintpalette.fill"
    case .player: "play.fill"
    case .notifications: "bell.fill"
    case .content: "rectangle.stack.fill"
    case .algorithm: "slider.horizontal.3"
    case .focus: "scope"
    case .rss: "dot.radiowaves.up.forward"
    case .downloads: "arrow.down"
    case .data: "externaldrive.fill"
    case .privacy: "hand.raised.fill"
    case .blocked: "nosign"
    case .api: "key.fill"
    case .diagnostics: "ladybug.fill"
    case .about: "info"
    }
  }
}
