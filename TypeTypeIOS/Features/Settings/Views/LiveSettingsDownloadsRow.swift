import SwiftUI

struct LiveSettingsDownloadsRow: View {
  let dependencies: AppDependencies
  @ObservedObject var center: LiveDownloadCenter

  var body: some View {
    LiveSettingsLinkRow(
      title: "Downloads",
      subtitle: "Videos saved for offline viewing",
      icon: "arrow.down",
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
