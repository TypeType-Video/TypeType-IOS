import SwiftUI

struct DemoWatchView: View {
  let video: DemoVideo
  @EnvironmentObject var session: DemoSessionStore
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Environment(\.verticalSizeClass) var verticalSizeClass
  @State var audioOnly = false
  @State var autoplay = true
  @State var selectedVideo: DemoVideo?
  @State var toastMessage: String?
  @State var autoplayTarget: DemoVideo?
  @State var selectedChannel: DemoSearchChannel?
  @State var keepsPlaybackExpanded = false
  @State var pendingExternalURL: URL?
  var controller: DemoPlayerController {
    session.playerController
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 0) {
          DemoWatchPlayerView(
            controller: controller,
            video: displayVideo,
            audioOnly: $audioOnly,
            autoplayTarget: autoplayTarget,
            autoplaySeconds: session.preferences.autoplayCountdownSeconds,
            onAutoplayPlay: playAutoplayTarget,
            onAutoplayCancel: cancelAutoplay
          )
          .id("demo.watch.player.top")
          .clipShape(playerShape)
          .contentShape(playerShape)
          .padding(.horizontal, playerHorizontalPadding)

          if session.preferences.sponsorBlock {
            DemoSponsorBlockOverlay(
              controller: controller,
              video: displayVideo
            )
            .padding(.horizontal, contentPadding)
            .padding(.top, 10)
          }

          VStack(alignment: .leading, spacing: 22) {
            DemoWatchHeaderView(
              controller: controller,
              video: displayVideo,
              onChannelSelect: openChannel
            )
            Divider()
            DemoWatchActionsView(
              video: displayVideo,
              audioOnly: $audioOnly,
              toastMessage: $toastMessage
            )
            DemoWatchDescriptionView(
              video: displayVideo,
              controller: controller,
              onOpenURL: routeLink
            )
            DemoWatchQueueView(onSelect: selectRelated)
            if session.preferences.loadsComments {
              DemoWatchCommentsView(
                onSeekTimestamp: seekFromText,
                onOpenURL: routeLink
              )
            }
            Divider()
            if session.preferences.showsRelated {
              DemoWatchRelatedView(
                currentVideoID: video.id,
                onSelect: selectRelated,
                autoplay: $autoplay
              )
            }
          }
          .foregroundStyle(.primary)
          .padding(.horizontal, contentPadding)
          .padding(.top, 20)
          .padding(.bottom, 34)
        }
      }
      .onChange(of: verticalSizeClass) {
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(180))
          proxy.scrollTo("demo.watch.player.top", anchor: .top)
        }
      }
    }
    .background(DemoTheme.background)
    .demoExternalLinkAlert(pendingURL: $pendingExternalURL)
    .preferredColorScheme(session.preferences.colorScheme)
    .navigationTitle("Watch")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(
      DemoTheme.background.opacity(0.96),
      for: .navigationBar
    )
    .onAppear {
      keepsPlaybackExpanded = false
      autoplay = session.preferences.autoplay
      audioOnly = session.preferences.audioOnlyPlayback
      controller.setLooping(session.preferences.loopPlayback)
      controller.setBackgroundAudioEnabled(session.preferences.backgroundAudio)
      controller.setAudioGain(percent: session.preferences.audioGainPercent)
      session.presentPlayback(video)
      presentTestPlaybackEndIfRequested()
    }
    .onChange(of: autoplay) {
      session.setPreference(\.autoplay, to: autoplay)
    }
    .onChange(of: session.preferences.autoplay) {
      autoplay = session.preferences.autoplay
    }
    .onChange(of: audioOnly) {
      session.setPreference(\.audioOnlyPlayback, to: audioOnly)
    }
    .onChange(of: session.preferences.backgroundAudio) {
      controller.setBackgroundAudioEnabled(session.preferences.backgroundAudio)
    }
    .onChange(of: session.preferences.audioGainPercent) {
      controller.setAudioGain(percent: session.preferences.audioGainPercent)
    }
    .onChange(of: controller.playbackEndSequence) {
      handlePlaybackEnded()
    }
    .onDisappear {
      if !keepsPlaybackExpanded { session.collapsePlayback(for: video.id) }
    }
    .navigationDestination(item: $selectedVideo) { nextVideo in
      DemoWatchView(video: nextVideo)
    }
    .navigationDestination(item: $selectedChannel) { channel in
      DemoSearchChannelDetailView(channel: channel)
    }
    .overlay(alignment: .bottom) {
      if let toastMessage {
        Text(toastMessage)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.primary)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(.regularMaterial)
          .clipShape(Capsule())
          .padding(.bottom, 16)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .accessibilityIdentifier("demo.watch.toast")
      }
    }
    .accessibilityIdentifier("demo.watch.screen")
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }
}
