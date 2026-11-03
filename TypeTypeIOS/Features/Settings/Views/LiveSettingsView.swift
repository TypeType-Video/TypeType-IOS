import SwiftUI

struct LiveSettingsView: View {
  @StateObject var viewModel: LiveSettingsViewModel
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var preferences: LiveAppPreferencesStore
  @ObservedObject private var playbackCoordinator: LivePlaybackCoordinator

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _preferences = ObservedObject(wrappedValue: coordinator.dependencies.appPreferences)
    let playbackCoordinator = coordinator.dependencies.playbackCoordinator
    self.playbackCoordinator = playbackCoordinator
    _viewModel = StateObject(wrappedValue: Self.makeViewModel(for: coordinator))
  }

  @MainActor
  static func makeViewModel(for coordinator: RootCoordinator) -> LiveSettingsViewModel {
    let dependencies = coordinator.dependencies
    let playbackCoordinator = dependencies.playbackCoordinator
    return LiveSettingsViewModel(
      service: dependencies.settingsService,
      serviceSelection: dependencies.serviceSelection,
      deArrowStore: dependencies.deArrowStore,
      connectivity: dependencies.connectivityMonitor,
      onSaved: { playbackCoordinator.applySettings($0) }
    )
  }

  var body: some View {
    content
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .task { await viewModel.prepare() }
      .accessibilityIdentifier("live.settings.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .settings, count: 9)
    case let .failed(message):
      ContentUnavailableView {
        Label("Settings unavailable", systemImage: "gear.badge.xmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      settingsList
    }
  }

  private var settingsList: some View {
    List {
      LiveSection {
        LiveSettingsAccountCard(coordinator: coordinator)
      }
      ForEach(Array(coordinator.settingsGroups.enumerated()), id: \.offset) { index, pages in
        group(pages, title: LiveSettingsPage.groupTitles[index])
      }
    }
    .contentMargins(.top, 8, for: .scrollContent)
    .padding(.bottom, playbackCoordinator.showsMiniPlayer ? 82 : 0)
    .liveGroupedList()
    .tint(preferences.preferences.accent)
  }

  @ViewBuilder
  private func group(_ pages: [LiveSettingsPage], title: String?) -> some View {
    if let title {
      LiveSection { rows(pages) } header: { Text(LocalizedStringKey(title)).liveSectionHeader() }
    } else {
      LiveSection { rows(pages) }
    }
  }

  private func rows(_ pages: [LiveSettingsPage]) -> some View {
    ForEach(pages) { page in
      NavigationLink {
        LiveSettingsDestination(page: page, coordinator: coordinator, viewModel: viewModel, preferences: preferences)
      } label: {
        LiveSettingsPageLabel(page: page, downloads: coordinator.dependencies.downloadCenter)
      }
    }
  }
}
