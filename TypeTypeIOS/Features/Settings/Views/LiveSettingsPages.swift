import SwiftUI

struct LiveSettingsEditingPage<Content: View>: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  let dependencies: AppDependencies
  @ViewBuilder let content: () -> Content

  var body: some View {
    Form {
      content()

      if let message = viewModel.message {
        Section {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
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
      Section("Instances") {
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
      }

      if let user = coordinator.currentUser {
        Section("Account") {
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
        }
      }
    }
    .navigationTitle("Instances and accounts")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsAppearanceView: View {
  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      Section("Appearance") {
        Picker(
          "Accent color",
          selection: preferences.binding(\.accentColor)
        ) {
          ForEach(LiveAccentColor.allCases) { color in
            Text(color.title).tag(color)
          }
        }
        Picker(
          "Personality",
          selection: preferences.binding(\.appearancePersonality)
        ) {
          ForEach(LiveAppearancePersonality.allCases) { personality in
            Text(personality.title).tag(personality)
          }
        }
        Picker(
          "Color scheme",
          selection: preferences.binding(\.appearanceMode)
        ) {
          ForEach(LiveAppearanceMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        Toggle("AMOLED black", isOn: preferences.binding(\.appearanceAmoled))
        Picker("Theme", selection: preferences.binding(\.appearanceTheme)) {
          ForEach(LiveAppearanceTheme.allCases) { theme in
            Text(theme.title).tag(theme)
          }
        }
        Picker("Font", selection: preferences.binding(\.appearanceFont)) {
          ForEach(LiveAppearanceFont.allCases) { font in
            Text(font.title).tag(font)
          }
        }
        Picker("Motion", selection: preferences.binding(\.appearanceMotion)) {
          ForEach(LiveAppearanceMotion.allCases) { motion in
            Text(motion.title).tag(motion)
          }
        }
      }

      if preferences.preferences.appearancePersonality == .manga {
        Section("Manga") {
          Picker("Paper", selection: preferences.binding(\.mangaPaper)) {
            ForEach(LiveMangaPaper.allCases) { paper in
              Text(paper.title).tag(paper)
            }
          }
          Picker(
            "Headline marker",
            selection: preferences.binding(\.mangaHeadlineMarker)
          ) {
            ForEach(LiveMangaHeadlineMarker.allCases) { marker in
              Text(marker.title).tag(marker)
            }
          }
          Toggle(
            "Screentone",
            isOn: preferences.binding(\.mangaScreentone)
          )
          Toggle(
            "Speed lines",
            isOn: preferences.binding(\.mangaSpeedLines)
          )
          Toggle(
            "Starburst",
            isOn: preferences.binding(\.mangaStarburst)
          )
          Toggle(
            "Inked icons",
            isOn: preferences.binding(\.mangaInkedIcons)
          )
          Toggle(
            "Panel tilt",
            isOn: preferences.binding(\.mangaPanelTilt)
          )
        }
      }
    }
    .navigationTitle("Appearance")
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
      Section("Visible surfaces") {
        Toggle("Hide Shorts", isOn: $viewModel.draft.hideShorts)
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
      Section("Gestures") {
        Toggle(
          "Accessible player controls",
          isOn: preferences.binding(\.playerAccessibleControlsEnabled)
        )
        Toggle(
          "Double-tap to seek",
          isOn: preferences.binding(\.playerDoubleTapSeekEnabled)
        )
        if preferences.preferences.playerDoubleTapSeekEnabled {
          Picker(
            "Double-tap seek time",
            selection: preferences.binding(
              \.playerDoubleTapSeekSeconds
            )
          ) {
            ForEach([5, 10, 15, 20, 30], id: \.self) { seconds in
              Text("\(seconds)s").tag(seconds)
            }
          }
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
      }
      Section("Default codec") {
        Picker("Preferred codec", selection: preferences.binding(
          \.playerPreferredCodec
        )) {
          Text("Smart").tag("recommended")
          Text("AV1").tag("av1")
          Text("VP9").tag("vp9")
          Text("H.264").tag("h264")
        }
      }
      Section("Bullet comments") {
        Toggle(
          "Show bullet comments",
          isOn: preferences.binding(\.danmakuEnabled)
        )
        if preferences.preferences.danmakuEnabled {
          Picker(
            "Danmaku speed",
            selection: preferences.binding(\.danmakuSpeed)
          ) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { value in
              Text("\(value)x").tag(value)
            }
          }
          Picker(
            "Danmaku size",
            selection: preferences.binding(\.danmakuSize)
          ) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { value in
              Text("\(Int(value * 100))%").tag(value)
            }
          }
        }
      }
      LiveSettingsLanguageSection(settings: $viewModel.draft)
      LiveSettingsSponsorBlockSection(settings: $viewModel.draft)
    }
    .navigationTitle("Player")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var localPlaybackSection: some View {
    Section("Device playback") {
      Toggle(
        "Autoplay next video",
        isOn: preferences.binding(\.playerAutoplayEnabled)
      )
      if preferences.preferences.playerAutoplayEnabled {
        Picker(
          "Autoplay countdown",
          selection: preferences.binding(
            \.playerAutoplayCountdownSeconds
          )
        ) {
          Text("Immediate").tag(0)
          ForEach([3, 5, 10, 15, 20, 30], id: \.self) { seconds in
            Text("\(seconds)s").tag(seconds)
          }
        }
      }
      Toggle(
        "Audio-only playback",
        isOn: preferences.binding(\.playerAudioOnlyPlayback)
      )
      Toggle(
        "Pause in background",
        isOn: preferences.binding(\.playerPauseInBackground)
      )
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
    }
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
  }
}
