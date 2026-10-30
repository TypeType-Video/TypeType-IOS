import SwiftUI

extension LiveSettingsView {
  @ViewBuilder
  var experienceRows: some View {
    LiveSettingsLinkRow(
      title: "Appearance",
      subtitle: "Theme, color and font",
      icon: "paintpalette.fill"
    ) {
      LiveSettingsAppearanceView(viewModel: viewModel, preferences: preferences)
    }
    LiveSettingsLinkRow(
      title: "Player",
      subtitle: "Playback, gestures, languages, SponsorBlock",
      icon: "play.fill"
    ) {
      LiveSettingsPlayerView(viewModel: viewModel, preferences: preferences)
    }
    LiveSettingsLinkRow(
      title: "Push notifications",
      subtitle: "Channels that alert you",
      icon: "bell.fill"
    ) {
      LiveNotificationSettingsView(dependencies: coordinator.dependencies)
    }
  }

  @ViewBuilder
  var contentRows: some View {
    LiveSettingsLinkRow(
      title: "Content",
      subtitle: "Home page, DeArrow, hidden sections",
      icon: "rectangle.stack.fill"
    ) {
      LiveSettingsContentView(dependencies: coordinator.dependencies, viewModel: viewModel)
    }
    if coordinator.dependencies.rssEnabled,
      let rssFeedService = coordinator.dependencies.rssFeedService
    {
      LiveSettingsLinkRow(
        title: "Private RSS feeds",
        subtitle: "Private links to your feeds",
        icon: "dot.radiowaves.up.forward"
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
    LiveSettingsDownloadsRow(
      dependencies: coordinator.dependencies,
      center: coordinator.dependencies.downloadCenter
    )
    LiveSettingsLinkRow(
      title: "Data and backups",
      subtitle: "Import and export your data",
      icon: "externaldrive.fill"
    ) {
      LivePortabilityView(
        service: coordinator.dependencies.portabilityService,
        importService: coordinator.dependencies.importService
      )
    }
    LiveSettingsLinkRow(
      title: "Privacy",
      subtitle: "Watch history and stored activity",
      icon: "hand.raised.fill"
    ) {
      LiveSettingsPrivacyView(dependencies: coordinator.dependencies, viewModel: viewModel)
    }
  }

  @ViewBuilder
  var advancedRows: some View {
    LiveSettingsLinkRow(
      title: "Blocked",
      subtitle: "Hidden channels, videos and keywords",
      icon: "nosign"
    ) {
      LiveContentControlsView(
        service: coordinator.dependencies.contentControlsService,
        canCreateGlobal: coordinator.currentUser?.role != .user
      )
    }
    LiveSettingsLinkRow(
      title: "Diagnostics",
      subtitle: "Recent requests, for troubleshooting",
      icon: "ladybug.fill"
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
      subtitle: "Versions and license",
      icon: "info"
    ) {
      LiveAboutView(coordinator: coordinator, versionService: coordinator.dependencies.versionService)
    }
  }
}
