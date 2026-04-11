import SwiftUI

struct HomePlaceholderView: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("TypeType iOS")
          .font(.title2.weight(.semibold))
        if let server = coordinator.selectedServer {
          Text("Connected to \(server.name)")
            .foregroundStyle(.secondary)
        }
        if let session = coordinator.currentSession {
          Text("Signed in as \(session.userEmail)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .navigationTitle("Home")
    }
  }
}
