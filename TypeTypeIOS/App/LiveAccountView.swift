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
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          accountSection
          instanceSection
          preferencesSection
          supportSection
          administrationSection
          signOutSection
        }
        .padding(.vertical, 16)
      }
      .background(DemoTheme.pageBackground)
      .navigationTitle("More")
    }
    .accessibilityIdentifier("live.account.screen")
  }
}
