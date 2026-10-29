import AVKit
import SwiftUI

/// Downloads play on the online watch page. The record keeps only title and URL, so metadata is thin.
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
      // Pull down from the video area only, so the page scroll is never fought; audio keeps playing.
      .simultaneousGesture(
        DragGesture(minimumDistance: 30)
          .onEnded { value in
            guard value.translation.height > 120,
              abs(value.translation.height) > abs(value.translation.width),
              value.startLocation.y < 320
            else { return }
            dismiss()
          }
      )
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
        }
      }
    }
    .task {
      await controller.installOffline(
        stream: item.watchStream,
        fileURL: item.fileURL
      )
    }
    .onDisappear {
      // Offline playback uses the regular AVPlayer path, not nativePlayback;
      // stop the controller itself so closing the cover cannot leave a local
      // player running behind Downloads.
      controller.stop()
    }
    .accessibilityIdentifier("live.offline-player")
  }
}
