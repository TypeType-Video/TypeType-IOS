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
    _viewModel = StateObject(
      wrappedValue: LiveSettingsViewModel(
        service: coordinator.dependencies.settingsService,
        serviceSelection: coordinator.dependencies.serviceSelection,
        deArrowStore: coordinator.dependencies.deArrowStore,
        onSaved: { playbackCoordinator.applySettings($0) }
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
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
        LiveSettingsAccountCard(
          coordinator: coordinator,
          connectivity: coordinator.dependencies.connectivityMonitor
        )
      }

      LiveSection {
        experienceRows
      }
      LiveSection {
        contentRows
      }
      LiveSection {
        dataRows
      } header: {
        Text("Your data").liveSettingsHeader()
      }
      LiveSection {
        advancedRows
      } header: {
        Text("Advanced").liveSettingsHeader()
      }
      LiveSection {
        aboutRow
      }
    }
    .padding(.bottom, playbackCoordinator.showsMiniPlayer ? 82 : 0)
    .liveGroupedList()
    .tint(preferences.preferences.accent)
  }
}
