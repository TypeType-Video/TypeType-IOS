import SwiftUI

struct LiveSettingsEditingPage<Content: View>: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  let dependencies: AppDependencies
  @ViewBuilder let content: () -> Content

  var body: some View {
    List {
      content()

      if let message = viewModel.message {
        LiveSection {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .liveGroupedList()
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if viewModel.hasChanges {
          Button("Reset") { viewModel.resetDraft() }
        }
        Button("Save") {
          Task {
            guard let settings = await viewModel.save() else { return }
            dependencies.playbackCoordinator.applySettings(settings)
          }
        }
        .disabled(!viewModel.hasChanges || viewModel.isSaving)
        .accessibilityIdentifier("live.settings.save")
      }
    }
    .alert("Settings", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}

struct LiveSettingsAccountsView: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    List {
      LiveSection {
        ForEach(coordinator.servers) { server in
          Button {
            Task { await coordinator.selectServer(server) }
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 3) {
                Text(server.name)
                  .foregroundStyle(.primary)
                Text(server.baseURLString)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              if coordinator.selectedServer?.id == server.id {
                Image(systemName: "checkmark")
                  .foregroundStyle(.tint)
              }
            }
          }
        }

        Button("Add instance") {
          coordinator.showServerSetup()
        }
      } header: {
        Text("Instances").liveSectionHeader()
      }

      if let user = coordinator.currentUser {
        LiveSection {
          LabeledContent(
            "Username",
            value: user.publicUsername ?? "Guest"
          )
          if !user.id.hasPrefix("guest:") {
            NavigationLink("Profile") {
              LiveProfileView(coordinator: coordinator, user: user)
            }
            if coordinator.dependencies.accountProfileService != nil {
              NavigationLink("Account profiles") {
                LiveAccountProfilesView(coordinator: coordinator)
              }
            }
          }
        } header: {
        Text("Account").liveSectionHeader()
      }
      }
    }
      .liveGroupedList()
    .navigationTitle("Instances and accounts")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsContentView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      LiveSettingsDiscoverySection(
        settings: $viewModel.draft,
        services: dependencies.serviceSelection.services
      )
      LiveSection {
        Toggle("Hide Shorts", isOn: $viewModel.draft.hideShorts)
      } header: {
        Text("Visible surfaces").liveSectionHeader()
      }
    }
    .navigationTitle("Content")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsPlayerView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      LiveSettingsPlaybackSection(settings: $viewModel.draft)
      localPlaybackSection
      LiveSection {
        Toggle(
          "Accessible player controls",
          isOn: preferences.binding(\.playerAccessibleControlsEnabled)
        )
        Toggle(
          "Double-tap to seek",
          isOn: preferences.binding(\.playerDoubleTapSeekEnabled)
        )
        if preferences.preferences.playerDoubleTapSeekEnabled {
          LiveOptionMenu(
            "Double-tap seek time",
            selection: preferences.binding(\.playerDoubleTapSeekSeconds),
            options: [5, 10, 15, 20, 30].map { ($0, "\($0)s") }
          )
        }
        Toggle(
          "Swipe to seek",
          isOn: preferences.binding(\.playerSwipeSeekEnabled)
        )
        Toggle(
          "Brightness and volume swipe",
          isOn: preferences.binding(
            \.playerSwipeBrightnessVolumeEnabled
          )
        )
        Toggle(
          "Long-press to speed up",
          isOn: preferences.binding(\.playerLongPressSpeedEnabled)
        )
      } header: {
        Text("Gestures").liveSectionHeader()
      }
      LiveSection {
        LiveOptionMenu(
          "Preferred codec",
          selection: preferences.binding(\.playerPreferredCodec),
          options: [
            ("recommended", "Smart"),
            ("av1", "AV1"),
            ("vp9", "VP9"),
            ("h264", "H.264"),
          ]
        )
      } header: {
        Text("Default codec").liveSectionHeader()
      }
      LiveSection {
        Toggle(
          "Show bullet comments",
          isOn: preferences.binding(\.danmakuEnabled)
        )
        if preferences.preferences.danmakuEnabled {
          LiveOptionMenu(
            "Danmaku speed",
            selection: preferences.binding(\.danmakuSpeed),
            options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map { ($0, "\($0)x") }
          )
          LiveOptionMenu(
            "Danmaku size",
            selection: preferences.binding(\.danmakuSize),
            options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map { ($0, "\(Int($0 * 100))%") }
          )
        }
      } header: {
        Text("Bullet comments").liveSectionHeader()
      }
      LiveSettingsLanguageSection(settings: $viewModel.draft)
      LiveSettingsSponsorBlockSection(settings: $viewModel.draft)
    }
    .navigationTitle("Player")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var localPlaybackSection: some View {
    LiveSection {
      Toggle(
        "Autoplay on this device",
        isOn: preferences.binding(\.playerAutoplayEnabled)
      )
      if preferences.preferences.playerAutoplayEnabled {
        LiveOptionMenu(
          "Autoplay countdown",
          selection: preferences.binding(\.playerAutoplayCountdownSeconds),
          options: [(0, "Immediate")]
            + [3, 5, 10, 15, 20, 30].map { ($0, "\($0)s") }
        )
      }
      Toggle(
        "Audio-only playback",
        isOn: preferences.binding(\.playerAudioOnlyPlayback)
      )
      Toggle(
        "Pause in background",
        isOn: preferences.binding(\.playerPauseInBackground)
      )
    } header: {
        Text("Device playback").liveSectionHeader()
      }
  }
}

struct LiveSettingsPrivacyView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      LiveSettingsPrivacySection(settings: $viewModel.draft)
      LiveSection {
        NavigationLink("Manage stored data") {
          LivePrivacyDataView(
            history: dependencies.historyService,
            searchHistory: dependencies.searchHistoryService,
            subscriptions: dependencies.subscriptionsService
          )
        }
      } header: {
        Text("Stored activity").liveSectionHeader()
      }
    }
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
  }
}
