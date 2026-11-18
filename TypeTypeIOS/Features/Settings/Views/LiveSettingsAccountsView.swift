import SwiftUI

struct LiveSettingsAccountsView: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    List {
      LiveSection {
        ForEach(coordinator.servers) { server in
          Button {
            Task { await coordinator.selectServer(server) }
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                  .font(.title3.weight(.semibold))
                  .foregroundStyle(.primary)
                Text(server.baseURL?.host() ?? server.baseURLString)
                  .font(.body)
                  .foregroundStyle(.secondary)
              }
              .padding(.vertical, 4)
              Spacer()
              if coordinator.selectedServer?.id == server.id {
                Image(systemName: "checkmark")
                  .foregroundStyle(.tint)
                  .accessibilityHidden(true)
              }
            }
          }
          .tint(Color.primary)
          .accessibilityAddTraits(coordinator.selectedServer?.id == server.id ? .isSelected : [])
        }

        Button("Add instance") {
          coordinator.showServerSetup()
        }
      } header: {
        Text("Instances").liveSectionHeader()
      }

      if coordinator.currentUser.map({ !$0.id.hasPrefix("guest:") }) == true {
        LiveSavedAccountsSection(coordinator: coordinator)
        if let service = coordinator.dependencies.deviceLinkService {
          LiveSection {
            NavigationLink {
              LiveDeviceLinkView(service: service)
            } label: {
              LiveSettingText(title: "Sign in another device", detail: "Enter the code shown on a TV or another device.")
            }
          }
        }
        if coordinator.instance?.youtubeRemoteLoginEnabled == true,
          let service = coordinator.dependencies.youtubeSessionService {
          LiveSection {
            NavigationLink {
              LiveYouTubeSessionView(coordinator: coordinator, service: service)
            } label: {
              LiveSettingText(title: "YouTube sign-in", detail: "For videos that need a signed-in YouTube session.")
            }
          }
        }
      }

      LiveSettingsLinkedAccountsRow(coordinator: coordinator)

      if let user = coordinator.currentUser {
        LiveSection {
          LabeledContent("Username") {
            Text(user.id.hasPrefix("guest:") ? String(localized: "Guest") : user.publicUsername ?? String(localized: "Not set"))
          }
          if !user.id.hasPrefix("guest:") {
            NavigationLink("Profile") {
              LiveProfileView(coordinator: coordinator, user: user)
            }
            if coordinator.dependencies.accountProfileService != nil {
              NavigationLink("Account profiles") {
                LiveAccountProfilesView(coordinator: coordinator)
              }
            }
          }
        } header: {
        Text("Account").liveSectionHeader()
      }
      }
    }
      .liveGroupedList()
    .navigationTitle("Instances and accounts")
    .navigationBarTitleDisplayMode(.inline)
  }
}
