import SwiftUI

struct LiveSettingsPlayerView: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    List {
      LiveSection {
        LiveSettingsLinkRow(title: "Playback", subtitle: "Autoplay, quality, speed, codec", icon: "play.fill") {
          LiveSettingsPlaybackPage(viewModel: viewModel, preferences: preferences)
        }
        LiveSettingsLinkRow(title: "Gestures", subtitle: "Tap, swipe and hold on the video", icon: "hand.tap.fill") {
          LiveSettingsGesturesPage(preferences: preferences)
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
      }
    }
    .liveGroupedList()
    .navigationTitle("Player")
    .navigationBarTitleDisplayMode(.inline)
  }
}
