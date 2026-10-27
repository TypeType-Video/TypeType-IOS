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

  @StateObject private var fullscreenControls = LiveNativeControlsState()

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
    .statusBarHidden(playbackCoordinator.controller?.isPresentingFullscreen == true)
    .overlay {
      if playbackCoordinator.controller?.isPresentingFullscreen == true,
        let controller = playbackCoordinator.controller {
        ZStack(alignment: .bottom) {
          Color.black.ignoresSafeArea()
          if let playback = controller.nativePlayback {
            LiveNativeVideoView(
              playback: playback,
              controller: controller,
              surface: .fullscreen
            )
            .ignoresSafeArea()
            .onTapGesture { fullscreenControls.tap() }
          }
          LiveNativePlayerControls(
            controller: controller,
            controls: fullscreenControls,
            isFullscreen: true
          ) {
            controller.exitNativeFullscreen()
          }
        }
        .transition(.opacity)
        .gesture(
          // Dragging down inside the landscape stage returns the player
          // page and the window together with it.
          DragGesture(minimumDistance: 30)
            .onEnded { value in
              guard value.translation.height > 120,
                abs(value.translation.width) < value.translation.height
              else { return }
              controller.exitNativeFullscreen()
            }
        )
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
