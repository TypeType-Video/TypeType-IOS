import Foundation

/// The three content tabs plus the iOS-18 search tab: history, playlists,
/// and collection kinds live INSIDE the library tab now (like beta), and
/// the account flow hangs off the home toolbar instead of its own tab.
enum LiveAuthenticatedTab: Hashable {
  case home
  case subscriptions
  case library
  case search
}

extension LiveAuthenticatedAppView {
  @MainActor
  func applyDefaultLandingPage() async {
    guard !didApplyDefaultLandingPage else { return }
    didApplyDefaultLandingPage = true
    guard let settings = try? await coordinator.dependencies
      .settingsService.settings()
    else {
      return
    }
    // Landing pages now open the tab AND pick the library section, so the
    // old per-collection landing pages keep their meaning.
    switch settings.defaultLandingPage {
    case "subscriptions":
      selectedTab = .subscriptions
    case "history":
      librarySection = .history
      selectedTab = .library
    case "playlists":
      librarySection = .playlists
      selectedTab = .library
    case "watch-later":
      librarySection = .watchLater
      selectedTab = .library
    case "favorites":
      librarySection = .favorites
      selectedTab = .library
    case "downloads":
      librarySection = .downloads
      selectedTab = .library
    default:
      selectedTab = .home
    }
  }
}
