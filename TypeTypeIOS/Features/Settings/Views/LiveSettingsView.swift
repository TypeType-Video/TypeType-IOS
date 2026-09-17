import SwiftUI

struct LiveSettingsView: View {
  @StateObject private var viewModel: LiveSettingsViewModel
  @ObservedObject private var coordinator: RootCoordinator

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
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

  private var settingsList: some View {
    List {
      settingsLink(
        "Instances and accounts",
        subtitle: "Switch instance or account"
      ) {
        LiveSettingsAccountsView(coordinator: coordinator)
      }

      if let user = coordinator.currentUser, !user.id.hasPrefix("guest:") {
        settingsLink("Profile", subtitle: "Public username, bio, avatar") {
          LiveProfileView(coordinator: coordinator, user: user)
        }
      }

      settingsLink(
        "Data and backups",
        subtitle: "Export or restore TypeType data, or import from "
          + "YouTube and PipePipe"
      ) {
        LiveImportView(service: coordinator.dependencies.importService)
      }

      if coordinator.dependencies.rssEnabled,
        let rssFeedService = coordinator.dependencies.rssFeedService {
        settingsLink(
          "Private RSS feeds",
          subtitle: "Create and manage private feed links"
        ) {
          LiveRssFeedsView(
            feedService: rssFeedService,
            subscriptionsService: coordinator.dependencies.subscriptionsService
          )
        }
      }

      settingsLink("Appearance", subtitle: "Theme and accent color") {
        LiveSettingsAppearanceView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel
        )
      }

      settingsLink(
        "Content",
        subtitle: "Discovery, DeArrow, and visible surfaces"
      ) {
        LiveSettingsContentView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel
        )
      }

      settingsLink(
        "Player",
        subtitle: "Gestures, autoplay, default quality"
      ) {
        LiveSettingsPlayerView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel
        )
      }

      settingsLink("Push notifications", subtitle: "New video alerts") {
        LiveNotificationSettingsView(dependencies: coordinator.dependencies)
      }

      settingsLink(
        "Storage",
        subtitle: "Cache, downloads, history limits"
      ) {
        LivePrivacyDataView(
          history: coordinator.dependencies.historyService,
          searchHistory: coordinator.dependencies.searchHistoryService,
          subscriptions: coordinator.dependencies.subscriptionsService
        )
      }

      settingsLink(
        "Privacy",
        subtitle: "Control history tracking and stored activity"
      ) {
        LiveSettingsPrivacyView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel
        )
      }

      settingsLink(
        "Diagnostics",
        subtitle: "Review redacted app and network activity"
      ) {
        LiveDiagnosticsView(
          store: coordinator.dependencies.diagnosticsStore,
          scopeProvider: {
            coordinator.dependencies.diagnosticScope()
          }
        )
      }

      settingsLink(
        "Blocked",
        subtitle: "Manage blocked keywords, channels, and videos"
      ) {
        LiveContentControlsView(
          service: coordinator.dependencies.contentControlsService,
          canCreateGlobal: coordinator.currentUser?.role != .user
        )
      }

      settingsLink("About", subtitle: "Version and credits") {
        DemoAboutView()
      }

      Button("Sign out", role: .destructive) {
        Task { await coordinator.signOut() }
      }
      .accessibilityIdentifier("live.settings.sign-out")
    }
    .listStyle(.insetGrouped)
  }

  private func settingsLink<Destination: View>(
    _ title: String,
    subtitle: String,
    @ViewBuilder destination: () -> Destination
  ) -> some View {
    NavigationLink {
      destination()
    } label: {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.body.weight(.medium))
          .foregroundStyle(.primary)
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
