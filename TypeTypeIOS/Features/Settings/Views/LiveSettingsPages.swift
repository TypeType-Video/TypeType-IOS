import SwiftUI

struct LiveSettingsEditingPage<Content: View>: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  let dependencies: AppDependencies
  @ViewBuilder let content: () -> Content

  var body: some View {
    List {
      content()

      if let message = viewModel.message {
        Section {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .id(DemoTheme.renderToken)
      .listStyle(.insetGrouped)
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
    .scrollContentBackground(.hidden)
    .background(DemoTheme.background)
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
      Section {
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
        Section {
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
      .id(DemoTheme.renderToken)
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(DemoTheme.background)
    .navigationTitle("Instances and accounts")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsAppearanceView: View {
  @Environment(\.colorScheme) private var colorScheme

  private var isEffectivelyDark: Bool {
    preferences.preferences.appearanceMode == .dark
      || (preferences.preferences.appearanceMode == .system
        && colorScheme == .dark)
  }

  let dependencies: AppDependencies
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSettingsEditingPage(
      viewModel: viewModel,
      dependencies: dependencies
    ) {
      Section {
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
        if isEffectivelyDark {
          Toggle("AMOLED black", isOn: preferences.binding(\.appearanceAmoled))
        }
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
      } header: {
        Text("Appearance").liveSectionHeader()
      }

      if preferences.preferences.appearancePersonality == .manga {
        Section {
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
        } header: {
        Text("Manga").liveSectionHeader()
      }
      }

      Section {
        Color.clear
          .accessibilityIdentifier("live.settings.appearance.preview")
          .frame(height: 0)
        ZStack {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(DemoTheme.background)
            .overlay {
              if preferences.preferences.appearancePersonality == .manga,
                preferences.preferences.mangaScreentone {
                  Canvas { context, size in
                    var x: CGFloat = 8
                    while x < size.width {
                      var y: CGFloat = 8
                      while y < size.height {
                        context.fill(
                          Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                          with: .color(.primary.opacity(0.10))
                        )
                        y += 12
                      }
                      x += 12
                    }
                  }
                }
            }
            .frame(height: 132)
            .overlay {
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(DemoTheme.separator, lineWidth: 1)
            }
            .rotationEffect(
              .degrees(
                preferences.preferences.appearancePersonality == .manga
                  && preferences.preferences.mangaPanelTilt ? -1 : 0
              )
            )

            VStack(alignment: .leading, spacing: 6) {
              Text("TypeType")
                .accessibilityIdentifier("live.settings.appearance.preview")
                .font(
                  preferences.preferences.appearancePersonality == .manga
                    ? .title2.weight(.black).monospaced()
                    : .title2.weight(.semibold)
                )
              Text("Theme preview")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
          }
          HStack(spacing: 8) {
            Circle()
              .fill(preferences.preferences.accentColor.color)
              .frame(width: 24, height: 24)
              .overlay(Circle().strokeBorder(DemoTheme.separator))
            Text(preferences.preferences.accentColor.title)
              .font(.caption)
            Spacer()
            Text(preferences.preferences.appearanceTheme.title)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        } header: {
        Text("Preview").liveSectionHeader()
      }
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.settings.appearance")
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
      Section {
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
      Section {
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
      } header: {
        Text("Gestures").liveSectionHeader()
      }
      Section {
        Picker("Preferred codec", selection: preferences.binding(
          \.playerPreferredCodec
        )) {
          Text("Smart").tag("recommended")
          Text("AV1").tag("av1")
          Text("VP9").tag("vp9")
          Text("H.264").tag("h264")
        }
      } header: {
        Text("Default codec").liveSectionHeader()
      }
      Section {
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
    Section {
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
      Section {
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
