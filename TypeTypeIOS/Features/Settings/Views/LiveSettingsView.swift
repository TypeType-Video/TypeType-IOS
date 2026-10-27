import SwiftUI

struct LiveSettingsView: View {
  @StateObject private var viewModel: LiveSettingsViewModel
  @ObservedObject private var coordinator: RootCoordinator
  @ObservedObject private var preferences = LiveAppPreferencesStore.shared
  @ObservedObject private var playbackCoordinator: LivePlaybackCoordinator

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    playbackCoordinator = coordinator.dependencies.playbackCoordinator
    _viewModel = StateObject(
      wrappedValue: LiveSettingsViewModel(
        service: coordinator.dependencies.settingsService,
        serviceSelection: coordinator.dependencies.serviceSelection,
        deArrowStore: coordinator.dependencies.deArrowStore
      )
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
      ProgressView("Loading settings")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

  /// The iOS-Settings hub: groups with plain headers, one-line rows with
  /// coloured icon tiles, no subtitles or duplicated actions. Profile and
  /// sign out live in the More tab.
  private var settingsList: some View {
    List {
      Section {
        LiveSettingsLinkRow(
          title: "Instances and accounts",
          icon: "person.crop.circle.fill",
          iconColor: .systemBlue
        ) {
          LiveSettingsAccountsView(coordinator: coordinator)
        }
        LiveSettingsLinkRow(
          title: "Push notifications",
          icon: "bell.fill",
          iconColor: .systemRed
        ) {
          LiveNotificationSettingsView(dependencies: coordinator.dependencies)
        }
        if coordinator.dependencies.rssEnabled,
          let rssFeedService = coordinator.dependencies.rssFeedService {
          LiveSettingsLinkRow(
            title: "Private RSS feeds",
            icon: "dot.radiowaves.left.and.right",
            iconColor: .systemBlue
          ) {
            LiveRssFeedsView(
              feedService: rssFeedService,
              subscriptionsService:
                coordinator.dependencies.subscriptionsService
            )
          }
        }
      } header: {
        Text("General")
      }

      Section {
        LiveSettingsLinkRow(
          title: "Appearance",
          icon: "paintpalette.fill",
          iconColor: .systemPurple
        ) {
          LiveSettingsAppearanceView(
            dependencies: coordinator.dependencies,
            viewModel: viewModel,
            preferences: LiveAppPreferencesStore.shared
          )
        }
        LiveSettingsLinkRow(
          title: "Player",
          icon: "play.circle.fill",
          iconColor: .systemBlue
        ) {
          LiveSettingsPlayerView(
            dependencies: coordinator.dependencies,
            viewModel: viewModel,
            preferences: LiveAppPreferencesStore.shared
          )
        }
      } header: {
        Text("Display and playback")
      }

      Section {
        LiveSettingsLinkRow(
          title: "Content",
          icon: "slider.horizontal.3",
          iconColor: .systemOrange
        ) {
          LiveSettingsContentView(
            dependencies: coordinator.dependencies,
            viewModel: viewModel
          )
        }
        LiveSettingsLinkRow(
          title: "Blocked",
          icon: "slash.circle.fill",
          iconColor: .systemGray
        ) {
          LiveContentControlsView(
            service: coordinator.dependencies.contentControlsService,
            canCreateGlobal: coordinator.currentUser?.role != .user
          )
        }
      } header: {
        Text("Content")
      }

      Section {
        LiveSettingsLinkRow(
          title: "Downloads",
          icon: "arrow.down.circle",
          iconColor: .systemTeal,
          badge: coordinator.dependencies.downloadCenter.activeCount
        ) {
          LiveDownloadsView(
            center: coordinator.dependencies.downloadCenter,
            onlinePlaybackCoordinator:
              coordinator.dependencies.playbackCoordinator
          )
        }
        LiveSettingsLinkRow(
          title: "Data and backups",
          icon: "square.and.arrow.up.fill",
          iconColor: .systemGreen
        ) {
          LivePortabilityView(
            service: coordinator.dependencies.portabilityService
          )
        }
        LiveSettingsLinkRow(
          title: "Import data",
          icon: "square.and.arrow.down.fill",
          iconColor: .systemGreen
        ) {
          LiveImportView(service: coordinator.dependencies.importService)
        }
        LiveSettingsLinkRow(
          title: "Privacy",
          icon: "lock.fill",
          iconColor: .systemBlue
        ) {
          LiveSettingsPrivacyView(
            dependencies: coordinator.dependencies,
            viewModel: viewModel
          )
        }
      } header: {
        Text("Data and privacy")
      }

      Section {
        LiveSettingsLinkRow(
          title: "Diagnostics",
          icon: "ladybug.fill",
          iconColor: .systemGray
        ) {
          LiveDiagnosticsView(
            store: coordinator.dependencies.diagnosticsStore,
            scopeProvider: {
              coordinator.dependencies.diagnosticScope()
            }
          )
        }
        LiveSettingsLinkRow(
          title: "About",
          icon: "info.circle.fill",
          iconColor: .systemGray
        ) {
          LiveAboutView(
            coordinator: coordinator,
            versionService: coordinator.dependencies.versionService
          )
        }
      } header: {
        Text("About")
      }
    }
    .padding(.bottom, playbackCoordinator.showsMiniPlayer ? 82 : 0)
    .liveThemedList()
    .liveThemeRepaint()
    .tint(preferences.preferences.accentColor.color)
  }
}
