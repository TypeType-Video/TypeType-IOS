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

  private var settingsList: some View {
    List {
      settingsLink(
        "Instances and accounts",
        icon: "person.crop.circle.fill",
        subtitle: "Switch instance or account"
      ) {
        LiveSettingsAccountsView(coordinator: coordinator)
      }

      if let user = coordinator.currentUser, !user.id.hasPrefix("guest:") {
        settingsLink(
          "Profile",
          icon: "person.fill",
          subtitle: "Public username, bio, avatar"
        ) {
          LiveProfileView(coordinator: coordinator, user: user)
        }
      }

      settingsLink(
        "Data and backups",
        icon: "square.and.arrow.up.fill",
        subtitle: "Export or restore TypeType data, or import from "
          + "YouTube and PipePipe"
        ) {
          LivePortabilityView(
            service: coordinator.dependencies.portabilityService
          )
        }

      if coordinator.dependencies.rssEnabled,
        let rssFeedService = coordinator.dependencies.rssFeedService {
        settingsLink(
          "Private RSS feeds",
          icon: "dot.radiowaves.left.and.right",
          subtitle: "Create and manage private feed links"
        ) {
          LiveRssFeedsView(
            feedService: rssFeedService,
            subscriptionsService: coordinator.dependencies.subscriptionsService
          )
        }
      }

      settingsLink(
        "Appearance",
        icon: "paintpalette.fill",
        subtitle: "Theme and accent color"
      ) {
        LiveSettingsAppearanceView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel,
          preferences: LiveAppPreferencesStore.shared
        )
      }

      settingsLink(
        "Content",
        icon: "slider.horizontal.3",
        subtitle: "Discovery, DeArrow, and visible surfaces"
      ) {
        LiveSettingsContentView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel
        )
      }

      settingsLink(
        "Player",
        icon: "play.circle.fill",
        subtitle: "Gestures, autoplay, default quality"
      ) {
        LiveSettingsPlayerView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel,
          preferences: LiveAppPreferencesStore.shared
        )
      }

      settingsLink(
        "Push notifications",
        icon: "bell.fill",
        subtitle: "New video alerts via UnifiedPush"
      ) {
        LiveNotificationSettingsView(dependencies: coordinator.dependencies)
      }

        settingsLink(
          "Storage",
          icon: "internaldrive.fill",
          subtitle: "Cache, downloads, history limits"
        ) {
          LiveDownloadsView(
            center: coordinator.dependencies.downloadCenter,
            onlinePlaybackCoordinator:
              coordinator.dependencies.playbackCoordinator
          )
        }

      settingsLink(
        "Privacy",
        icon: "lock.fill",
        subtitle: "Control history tracking and stored activity"
      ) {
        LiveSettingsPrivacyView(
          dependencies: coordinator.dependencies,
          viewModel: viewModel
        )
      }

      settingsLink(
        "Diagnostics",
        icon: "ladybug.fill",
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
        icon: "slash.circle.fill",
        subtitle: "Manage blocked keywords, channels, and videos"
      ) {
        LiveContentControlsView(
          service: coordinator.dependencies.contentControlsService,
          canCreateGlobal: coordinator.currentUser?.role != .user
        )
      }

      settingsLink(
        "About",
        icon: "info.circle.fill",
        subtitle: "Version and credits"
      ) {
        LiveAboutView(
          coordinator: coordinator,
          versionService: coordinator.dependencies.versionService
        )
      }

      Button {
        Task { await coordinator.signOut() }
      } label: {
        HStack(spacing: 14) {
          Image(systemName: "rectangle.portrait.and.arrow.right")
          Text("Sign out")
            .font(.body.weight(.semibold))
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .listRowInsets(
        EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
      )
      .accessibilityIdentifier("live.settings.sign-out")
    }
    .padding(.bottom, playbackCoordinator.showsMiniPlayer ? 82 : 0)
      .liveThemedList()
      .liveThemeRepaint()
    .tint(preferences.preferences.accentColor.color)
  }

  private func settingsLink<Destination: View>(
    _ title: String,
    icon: String,
    subtitle: String,
    @ViewBuilder destination: () -> Destination
  ) -> some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 24, weight: .regular))
          .foregroundStyle(.tint)
          .frame(width: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
      .padding(.vertical, 2)
    }
      .listRowInsets(
        EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
      )
      .listRowSeparatorTint(.secondary.opacity(0.48))
  }
}
