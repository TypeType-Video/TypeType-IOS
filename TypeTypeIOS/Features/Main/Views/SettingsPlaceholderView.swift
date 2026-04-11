import SwiftUI

struct SettingsPlaceholderView: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    NavigationStack {
      Form {
        if let selected = coordinator.selectedServer {
          Section("Current Server") {
            Text(selected.name)
            Text(selected.baseURLString)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }

        Section {
          Button("Change Server") {
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
