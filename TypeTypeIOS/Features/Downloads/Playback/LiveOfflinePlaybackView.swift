import AVKit
import SwiftUI

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
      .background(LiveThemeBackground().ignoresSafeArea())
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
      // Offline playback runs on AVPlayer, not the native engine: stop the controller so closing never leaves a
      // player running.
      controller.stop()
    }
    .accessibilityIdentifier("live.offline-player")
  }
}
