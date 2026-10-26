import SwiftUI

struct LiveAccountView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var notificationCenter: LiveNotificationCenter
  @ObservedObject var downloadCenter: LiveDownloadCenter

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
    .accessibilityIdentifier("live.account.screen")
  }
}
