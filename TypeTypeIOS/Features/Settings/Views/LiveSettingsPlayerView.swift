import SwiftUI

struct LiveSettingsPlayerView: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore
  let profileService: LiveProfileServiceProtocol
  let canUploadIcon: Bool

  var body: some View {
    List {
      LiveSection {
        LiveSettingsLinkRow(title: "Playback", subtitle: "Autoplay, quality, speed, codec", icon: "play.fill") {
          LiveSettingsPlaybackPage(viewModel: viewModel, preferences: preferences)
        }
        LiveSettingsLinkRow(title: "Gestures", subtitle: "Tap, swipe and hold on the video", icon: "hand.tap.fill") {
          LiveSettingsGesturesPage(preferences: preferences, viewModel: viewModel)
        }
        if viewModel.draft.defaultService == 0 {
          LiveSettingsLinkRow(title: "Language and captions", subtitle: "Subtitles and audio track", icon: "captions.bubble.fill") {
            LiveSettingsLanguagePage(viewModel: viewModel)
          }
        }
      }
      LiveSection {
        LiveSettingsLinkRow(title: "SponsorBlock", subtitle: "Skip sponsors and other segments", icon: "forward.end.fill") {
          LiveSettingsSponsorBlockPage(viewModel: viewModel)
        }
        LiveSettingsLinkRow(title: "Bullet comments", subtitle: "Comments that scroll over the video", icon: "text.bubble.fill") {
          LiveSettingsDanmakuPage(preferences: preferences)
        }
        if viewModel.draft.seekbarIcon != nil {
          LiveSettingsLinkRow(title: "Seekbar icon", subtitle: "The icon that moves along the progress bar", icon: "tv.fill") {
            LiveSettingsSeekbarIconPage(viewModel: viewModel, service: profileService, canUpload: canUploadIcon)
          }
        }
      }
      LiveSection {
        LiveSettingToggle(
          "Animate GIFs in comments",
          help: "GIFs attached to comments stay still until you turn this on.",
          isOn: preferences.binding(\.commentsAnimateGIFs)
        )
      }
    }
    .liveGroupedList()
    .navigationTitle("Player")
    .navigationBarTitleDisplayMode(.inline)
  }
}
