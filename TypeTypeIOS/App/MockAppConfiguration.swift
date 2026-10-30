import Foundation

enum DemoLaunchDestination: Equatable {
  case auth
  case home
  case player
  case search
  case subscriptions
  case subscriptionChannels
  case history
  case playlists
  case more
}

enum MockAppConfiguration {
  static var isEnabled: Bool {
#if DEBUG
#if targetEnvironment(simulator)
    CommandLine.arguments.contains { argument in
      argument.hasPrefix("--typetype-demo-")
    }
#else
    false
#endif
#else
    false
#endif
  }

  static var initialAuthMode: AuthMode {
    if CommandLine.arguments.contains("--typetype-demo-register") {
      return .register
    }
    return .signIn
  }

  static var launchDestination: DemoLaunchDestination {
    if CommandLine.arguments.contains("--typetype-demo-search") {
      return .search
    }
    if CommandLine.arguments.contains("--typetype-demo-player") {
      return .player
    }
    if CommandLine.arguments.contains("--typetype-demo-subscription-channels") {
      return .subscriptionChannels
    }
    if CommandLine.arguments.contains("--typetype-demo-subscriptions") {
      return .subscriptions
    }
    if CommandLine.arguments.contains("--typetype-demo-history") {
      return .history
    }
    if CommandLine.arguments.contains("--typetype-demo-playlists") {
      return .playlists
    }
    if CommandLine.arguments.contains("--typetype-demo-more") {
      return .more
    }
    if CommandLine.arguments.contains("--typetype-demo-home") {
      return .home
    }
    return .auth
  }
}
