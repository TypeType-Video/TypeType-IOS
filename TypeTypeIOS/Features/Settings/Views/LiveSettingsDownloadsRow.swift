import SwiftUI

struct LiveSettingsDownloadsRow: View {
  let dependencies: AppDependencies
  @ObservedObject var center: LiveDownloadCenter

  var body: some View {
    LiveSettingsLinkRow(
      title: "Downloads",
      icon: "arrow.down",
      iconColor: .systemTeal,
      value: center.storageUsage > 0
        ? ByteCountFormatter.string(fromByteCount: center.storageUsage, countStyle: .file)
        : nil,
      badge: center.activeCount
    ) {
      LiveDownloadsView(
        dependencies: dependencies,
        center: center,
        onlinePlaybackCoordinator: dependencies.playbackCoordinator
      )
    }
  }
}
