import SwiftUI

struct LiveSettingsPlayerView: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    List {
      LiveSection {
        LiveSettingsLinkRow(title: "Playback", icon: "play.fill", iconColor: .systemBlue) {
          LiveSettingsPlaybackPage(viewModel: viewModel, preferences: preferences)
        }
        LiveSettingsLinkRow(title: "Gestures", icon: "hand.tap.fill", iconColor: .systemOrange) {
          LiveSettingsGesturesPage(preferences: preferences)
        }
        LiveSettingsLinkRow(title: "Language and captions", icon: "captions.bubble.fill", iconColor: .systemIndigo) {
          LiveSettingsLanguagePage(viewModel: viewModel)
        }
      }
      LiveSection {
        LiveSettingsLinkRow(title: "SponsorBlock", icon: "forward.end.fill", iconColor: .systemGreen) {
          LiveSettingsSponsorBlockPage(viewModel: viewModel)
        }
        LiveSettingsLinkRow(title: "Bullet comments", icon: "text.bubble.fill", iconColor: .systemPink) {
          LiveSettingsDanmakuPage(preferences: preferences)
        }
      }
    }
    .liveGroupedList()
    .navigationTitle("Player")
    .navigationBarTitleDisplayMode(.inline)
  }
}
