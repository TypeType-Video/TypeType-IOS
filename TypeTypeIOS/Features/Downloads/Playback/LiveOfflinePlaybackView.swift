import AVKit
import SwiftUI

/// Downloaded videos play on the SAME watch page as online ones: the full
/// player stage (HUD, gestures, fullscreen) over the metadata page. The
/// download record keeps only title and URL, so the page renders with thin
/// metadata (no channel box data, no counts) but the whole player works.
struct LiveOfflinePlaybackView: View {
  let item: LiveOfflinePlaybackItem
  let dependencies: AppDependencies
  @StateObject private var controller: LivePlayerController
  @Environment(\.dismiss) private var dismiss

  init(item: LiveOfflinePlaybackItem, dependencies: AppDependencies) {
    self.item = item
    self.dependencies = dependencies
    _controller = StateObject(
      wrappedValue: LivePlayerController(
        video: item.watchVideo,
        dependencies: dependencies,
        autoplay: true
      )
    )
  }

  var body: some View {
    NavigationStack {
      LiveVideoMetadataContentView(
        video: item.watchVideo,
        dependencies: dependencies,
        playerController: controller
      )
      .background(DemoThemeBackground().ignoresSafeArea())
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
        }
      }
    }
    .task {
      controller.installOffline(
        stream: item.watchStream,
        fileURL: item.fileURL
      )
    }
    .onDisappear {
      controller.stopNative()
    }
    .accessibilityIdentifier("live.offline-player")
  }
}
