import SwiftUI

struct LiveSettingsSearchResults: View {
  let results: [LiveSettingsSearchEntry]
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    if results.isEmpty {
      ContentUnavailableView.search
    } else {
      List(results) { entry in
        NavigationLink { destination(entry.target) } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: entry.title)
            Text(verbatim: entry.place).font(.footnote).foregroundStyle(.secondary)
          }
        }
        .accessibilityHint(Text("Opens \(entry.place)"))
      }
      .liveGroupedList()
    }
  }

  @ViewBuilder
  private func destination(_ target: LiveSettingsSearchTarget) -> some View {
    switch target {
    case let .page(page):
      LiveSettingsDestination(page: page, coordinator: coordinator, viewModel: viewModel, preferences: preferences)
    case .playback:
      LiveSettingsPlaybackPage(viewModel: viewModel, preferences: preferences)
    case .gestures:
      LiveSettingsGesturesPage(preferences: preferences, viewModel: viewModel)
    case .language:
      LiveSettingsLanguagePage(viewModel: viewModel)
    case .sponsorBlock:
      LiveSettingsSponsorBlockPage(viewModel: viewModel)
    case .danmaku:
      LiveSettingsDanmakuPage(preferences: preferences)
    }
  }
}
