import SwiftUI

struct SettingsPlaceholderView: View {
  @ObservedObject var coordinator: RootCoordinator

  @ViewBuilder
  private var serverSection: some View {
    if let selected = coordinator.selectedServer {
      Section("Current Server") {
        Text(selected.name)
        Text(selected.baseURLString)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private var switchServerSection: some View {
    if coordinator.servers.count > 1 {
      Section("Switch Server") {
        ForEach(coordinator.servers) { server in
          Button {
            coordinator.setSelectedServer(server)
          } label: {
            HStack {
              Text(server.name)
              Spacer()
              if coordinator.selectedServer?.id == server.id {
                Image(systemName: "checkmark")
                  .foregroundStyle(.green)
              }
            }
          }
        }
      }
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        serverSection

        if let session = coordinator.currentSession {
          Section("Session") {
            LabeledContent("Email", value: session.userEmail)
            LabeledContent("Role", value: session.role)
          }
        }

        switchServerSection

        Section {
          Button("Manage Servers") {
            coordinator.state = .serverSetup
          }
          Button("Sign Out", role: .destructive) {
            coordinator.signOut()
          }
        }
      }
      .navigationTitle("Settings")
    }
  }
}
