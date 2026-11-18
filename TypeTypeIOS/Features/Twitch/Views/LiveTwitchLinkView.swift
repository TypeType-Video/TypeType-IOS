import SwiftUI

struct LiveTwitchLinkView: View {
  let link: LiveTwitchLink
  let dependencies: AppDependencies

  var body: some View {
    if dependencies.twitchEnabled, let service = dependencies.twitchService, let route {
      LiveTwitchDestination(route: route, service: service)
        .navigationDestination(for: LiveTwitchRoute.self) { next in
          LiveTwitchDestination(route: next, service: service)
        }
        .environment(\.liveTwitchPlay) { dependencies.playbackCoordinator.open($0) }
        .environment(\.liveTwitchAccount, dependencies.twitchAccountService)
    } else {
      LiveTwitchMessage(text: Text("Twitch is not enabled on this instance."), systemImage: "dot.radiowaves.left.and.right", retry: nil)
    }
  }

  private var route: LiveTwitchRoute? {
    guard case let .channel(login) = link else { return nil }
    return .channel(login)
  }
}
