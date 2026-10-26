import SwiftUI

struct LiveVideoMetadataView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject private var playbackCoordinator: LivePlaybackCoordinator

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    self.dependencies = dependencies
    playbackCoordinator = dependencies.playbackCoordinator
  }

  var body: some View {
    Group {
      if let activeVideo = playbackCoordinator.currentVideo,
        let controller = playbackCoordinator.controller {
        LiveVideoMetadataContentView(
          video: activeVideo,
          dependencies: dependencies,
          playerController: controller
        )
        .id(ObjectIdentifier(controller))
      } else {
        ProgressView("Preparing video")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(DemoThemeBackground())
      .liveThemeRepaint()
      }
    }
    .task(id: video.url) {
      await Task.yield()
      guard !Task.isCancelled else { return }
      playbackCoordinator.open(video)
    }
    .onDisappear {
      let departingVideoURL = video.url
      Task { @MainActor in
        await Task.yield()
        guard playbackCoordinator.currentVideo?.url
          == departingVideoURL
        else {
          return
        }
        playbackCoordinator.minimize()
      }
    }
  }
}
