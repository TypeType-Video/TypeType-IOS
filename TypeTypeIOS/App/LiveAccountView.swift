import SwiftUI

struct LiveAccountView: View {
  @Environment(\.themePalette) var palette
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var notificationCenter: LiveNotificationCenter
  @ObservedObject var downloadCenter: LiveDownloadCenter
  @State var confirmsSignOut = false

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
      .liveGroupedList()
      .navigationTitle("More")
      .navigationBarTitleDisplayMode(.inline)
    }
    .accessibilityIdentifier("live.account.screen")
  }
}
