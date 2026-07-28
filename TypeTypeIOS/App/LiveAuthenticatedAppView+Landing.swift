import Foundation

enum LiveAuthenticatedTab: Hashable {
  case home
  case subscriptions
  case history
  case playlists
  case more
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
      selectedTab = .subscriptions
    case "history":
      selectedTab = .history
    case "playlists":
      selectedTab = .playlists
    case "watch-later":
      startupCollection = .watchLater
      selectedTab = .playlists
    case "favorites":
      startupCollection = .favorites
      selectedTab = .playlists
    default:
      selectedTab = .home
    }
  }
}
