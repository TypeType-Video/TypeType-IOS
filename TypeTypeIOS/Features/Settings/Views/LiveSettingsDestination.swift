import SwiftUI

struct LiveSettingsDestination: View {
  let page: LiveSettingsPage
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    let dependencies = coordinator.dependencies
    switch page {
    case .accounts:
      LiveSettingsAccountsView(coordinator: coordinator)
    case .appearance:
      LiveSettingsAppearanceView(viewModel: viewModel, preferences: preferences)
    case .player:
      LiveSettingsPlayerView(viewModel: viewModel, preferences: preferences)
    case .notifications:
      LiveNotificationSettingsView(dependencies: dependencies)
    case .content:
      LiveSettingsContentView(dependencies: dependencies, viewModel: viewModel)
    case .rss:
      if let feeds = dependencies.rssFeedService {
        LiveRssFeedsView(feedService: feeds, subscriptionsService: dependencies.subscriptionsService)
      }
    case .downloads:
      LiveDownloadsView(
        dependencies: dependencies,
        center: dependencies.downloadCenter
      )
    case .data:
      LivePortabilityView(service: dependencies.portabilityService, importService: dependencies.importService)
    case .privacy:
      LiveSettingsPrivacyView(dependencies: dependencies, viewModel: viewModel)
    case .blocked:
      LiveContentControlsView(
        service: dependencies.contentControlsService,
        canCreateGlobal: coordinator.currentUser?.role != .user,
        hiddenVideos: dependencies.hiddenVideos
      )
    case .diagnostics:
      LiveDiagnosticsView(
        store: dependencies.diagnosticsStore,
        crashReports: dependencies.crashReports,
        scopeProvider: { dependencies.diagnosticScope() }
      )
    case .about:
      LiveAboutView(coordinator: coordinator, versionService: dependencies.versionService)
    }
  }
}

struct LiveSettingsPageLabel: View {
  let page: LiveSettingsPage
  @ObservedObject var downloads: LiveDownloadCenter

  var body: some View {
    LiveSettingsRowLabel(
      title: page.title,
      subtitle: page.subtitle,
      icon: page.icon,
      value: page == .downloads && downloads.storageUsage > 0
        ? ByteCountFormatter.string(fromByteCount: downloads.storageUsage, countStyle: .file)
        : nil,
      badge: page == .downloads ? downloads.activeCount : 0
    )
  }
}

extension RootCoordinator {
  var settingsGroups: [[LiveSettingsPage]] {
    LiveSettingsPage.groups.map { group in
      group.filter { $0 != .rss || (dependencies.rssEnabled && dependencies.rssFeedService != nil) }
    }
  }
}
