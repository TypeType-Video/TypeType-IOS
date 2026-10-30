import SwiftUI

extension LiveSettingsView {
  @ViewBuilder
  var experienceRows: some View {
    LiveSettingsLinkRow(
      title: "Appearance",
      icon: "paintpalette.fill",
      iconColor: .systemIndigo
    ) {
      LiveSettingsAppearanceView(viewModel: viewModel, preferences: preferences)
    }
    LiveSettingsLinkRow(
      title: "Player",
      icon: "play.fill",
      iconColor: .systemBlue
    ) {
      LiveSettingsPlayerView(viewModel: viewModel, preferences: preferences)
    }
    LiveSettingsLinkRow(
      title: "Push notifications",
      icon: "bell.fill",
      iconColor: .systemRed
    ) {
      LiveNotificationSettingsView(dependencies: coordinator.dependencies)
    }
  }

  @ViewBuilder
  var contentRows: some View {
    LiveSettingsLinkRow(
      title: "Content",
      icon: "rectangle.stack.fill",
      iconColor: .systemPurple
    ) {
      LiveSettingsContentView(dependencies: coordinator.dependencies, viewModel: viewModel)
    }
    if coordinator.dependencies.rssEnabled,
      let rssFeedService = coordinator.dependencies.rssFeedService
    {
      LiveSettingsLinkRow(
        title: "Private RSS feeds",
        icon: "dot.radiowaves.up.forward",
        iconColor: .systemOrange
      ) {
        LiveRssFeedsView(
          feedService: rssFeedService,
          subscriptionsService: coordinator.dependencies.subscriptionsService
        )
      }
    }
  }

  @ViewBuilder
  var dataRows: some View {
    LiveSettingsLinkRow(
      title: "Downloads",
      icon: "arrow.down",
      iconColor: .systemTeal,
      badge: coordinator.dependencies.downloadCenter.activeCount
    ) {
      LiveDownloadsView(
        dependencies: coordinator.dependencies,
        center: coordinator.dependencies.downloadCenter,
        onlinePlaybackCoordinator: coordinator.dependencies.playbackCoordinator
      )
    }
    LiveSettingsLinkRow(
      title: "Data and backups",
      icon: "externaldrive.fill",
      iconColor: .systemGreen
    ) {
      LivePortabilityView(
        service: coordinator.dependencies.portabilityService,
        importService: coordinator.dependencies.importService
      )
    }
    LiveSettingsLinkRow(
      title: "Privacy",
      icon: "hand.raised.fill",
      iconColor: .systemBlue
    ) {
      LiveSettingsPrivacyView(dependencies: coordinator.dependencies, viewModel: viewModel)
    }
  }

  @ViewBuilder
  var advancedRows: some View {
    LiveSettingsLinkRow(
      title: "Blocked",
      icon: "nosign",
      iconColor: .systemGray
    ) {
      LiveContentControlsView(
        service: coordinator.dependencies.contentControlsService,
        canCreateGlobal: coordinator.currentUser?.role != .user
      )
    }
    LiveSettingsLinkRow(
      title: "Diagnostics",
      icon: "ladybug.fill",
      iconColor: .systemGray
    ) {
      LiveDiagnosticsView(
        store: coordinator.dependencies.diagnosticsStore,
        scopeProvider: { coordinator.dependencies.diagnosticScope() }
      )
    }
  }

  var aboutRow: some View {
    LiveSettingsLinkRow(
      title: "About",
      icon: "info",
      iconColor: .systemGray
    ) {
      LiveAboutView(coordinator: coordinator, versionService: coordinator.dependencies.versionService)
    }
  }
}
