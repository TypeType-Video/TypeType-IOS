import SwiftUI

struct LiveAccountView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var notificationCenter: LiveNotificationCenter
  @ObservedObject var downloadCenter: LiveDownloadCenter
  @State private var confirmsSignOut = false

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    notificationCenter = coordinator.dependencies.notificationCenter
    downloadCenter = coordinator.dependencies.downloadCenter
  }

  var body: some View {
    NavigationStack {
      List {
        accountSection
        instanceSection
        preferencesSection
        supportSection
        administrationSection
        signOutSection
      }
      .liveThemedList()
      .liveThemeRepaint()
      .navigationTitle("More")
      .navigationBarTitleDisplayMode(.inline)
    }
    .confirmationDialog(
      "Sign out of this instance?",
      isPresented: $confirmsSignOut,
      titleVisibility: .visible
    ) {
      Button("Sign out", role: .destructive) {
        Task { await coordinator.signOut() }
      }
    } message: {
      Text("You can sign back in any time.")
    }
    .accessibilityIdentifier("live.account.screen")
  }
}
