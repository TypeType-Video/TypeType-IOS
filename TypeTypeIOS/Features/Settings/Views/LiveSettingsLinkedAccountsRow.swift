import SwiftUI

struct LiveSettingsLinkedAccountsRow: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    if coordinator.currentUser != nil,
      let youtube = coordinator.dependencies.youtubeSessionService,
      let linked = coordinator.dependencies.linkedAccountsService {
      LiveSection {
        NavigationLink {
          LiveLinkedAccountsView(
            youtube: youtube, service: linked,
            twitch: coordinator.dependencies.twitchEnabled ? coordinator.dependencies.twitchAccountService : nil
          )
        } label: {
          LiveSettingText(title: "Linked accounts", detail: "Sign in to YouTube with a code and to BiliBili with a QR code.")
        }
      }
    }
  }
}
