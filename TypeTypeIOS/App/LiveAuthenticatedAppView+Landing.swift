import Foundation

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
    switch settings.defaultLandingPage {
    case "subscriptions":
      selectedTab.wrappedValue = .subscriptions
    case "history":
      librarySection = .history
      selectedTab.wrappedValue = .library
    case "playlists":
      librarySection = .playlists
      selectedTab.wrappedValue = .library
    case "watch-later":
      librarySection = .watchLater
      selectedTab.wrappedValue = .library
    case "favorites":
      librarySection = .favorites
      selectedTab.wrappedValue = .library
    case "downloads":
      librarySection = .downloads
      selectedTab.wrappedValue = .library
    default:
      selectedTab.wrappedValue = .home
    }
  }
}
