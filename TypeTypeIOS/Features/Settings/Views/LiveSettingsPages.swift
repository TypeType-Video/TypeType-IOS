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
      .liveThemeRepaint()
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
      .liveGroupedList()
      .liveThemeRepaint()
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
        LiveAppearanceThemeTiles(
          selection: preferences.binding(\.appearanceTheme),
          isDark: isEffectivelyDark
        )
        LiveAppearanceAccentDots(
          selection: preferences.binding(\.accentColor)
        )
      } header: {
        Text("Appearance").liveSectionHeader()
      }

      Section {
        LiveOptionMenu(
          "Color scheme",
          selection: preferences.binding(\.appearanceMode),
          options: LiveAppearanceMode.allCases.map { ($0, $0.title) }
        )
        // The AMOLED row is visible only when the app is effectively dark
        // (Dark, or System with a dark system) — in light it does nothing.
        if isEffectivelyDark {
          Toggle("AMOLED black", isOn: preferences.binding(\.appearanceAmoled)).liveRowFill()
        }
        LiveOptionMenu(
          "Font",
          selection: preferences.binding(\.appearanceFont),
          options: LiveAppearanceFont.allCases.map { ($0, $0.title) }
        )
        LiveOptionMenu(
          "Motion",
          selection: preferences.binding(\.appearanceMotion),
          options: LiveAppearanceMotion.allCases.map { ($0, $0.title) }
        )
      }
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.settings.appearance")
  }
}

/// Theme picker as live preview tiles: each theme's real surface colours in
/// a mini feed mock-up (dev feedback, plan 6.1; adapted from beta 9b680fe).
struct LiveAppearanceThemeTiles: View {
  @Binding var selection: LiveAppearanceTheme
  let isDark: Bool

  var body: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: 12) {
        ForEach(LiveAppearanceTheme.allCases) { theme in
          Button {
            selection = theme
          } label: {
            VStack(spacing: 6) {
              LiveAppearanceMiniScreen(theme: theme, isDark: isDark)
                .frame(width: 66, height: 96)
                .overlay {
                  RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                      DemoTheme.accent,
                      lineWidth: selection == theme ? 2.5 : 0
                    )
                }
              Text(theme.title)
                .font(
                  .caption2.weight(selection == theme ? .semibold : .regular)
                )
                .foregroundStyle(selection == theme ? DemoTheme.accent : .primary)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(theme.title)
          .accessibilityAddTraits(selection == theme ? .isSelected : [])
          .accessibilityIdentifier("live.settings.appearance.theme.\(theme.id)")
        }
      }
      .padding(.vertical, 8)
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.settings.appearance.themes")
  }
}

/// A tiny feed mock-up drawn in one theme's real surface colours.
struct LiveAppearanceMiniScreen: View {
  let theme: LiveAppearanceTheme
  let isDark: Bool

  var body: some View {
    let colors = DemoTheme.themeSurfaceColors(isDark: isDark, theme: theme)
    return RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(colors.background)
      .overlay(alignment: .topLeading) {
        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(colors.variant)
            .frame(height: 26)
          Capsule()
            .fill(textPrimary.opacity(0.75))
            .frame(width: 40, height: 5)
          Capsule()
            .fill(textSecondary.opacity(0.5))
            .frame(width: 28, height: 4)
          Capsule()
            .fill(DemoTheme.accent)
            .frame(width: 22, height: 7)
        }
        .padding(7)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .strokeBorder(colors.outline, lineWidth: 1)
      }
      .accessibilityHidden(true)
  }

  // Android text roles: onSurface = Zinc950 light / Zinc100 dark and
  // onSurfaceVariant = Zinc700 light / Zinc400 dark, not tinted per theme.
  private var textPrimary: Color {
    isDark
      ? Color(red: 0.957, green: 0.957, blue: 0.961)  // F4F4F5
      : Color(red: 0.035, green: 0.035, blue: 0.043)  // 09090B
  }

  private var textSecondary: Color {
    isDark
      ? Color(red: 0.631, green: 0.631, blue: 0.667)  // A1A1AA
      : Color(red: 0.247, green: 0.247, blue: 0.275)  // 3F3F46
  }
}

/// Accent colours as compact circles with a checkmark on the selected one.
struct LiveAppearanceAccentDots: View {
  @Binding var selection: LiveAccentColor

  var body: some View {
    HStack(spacing: 0) {
      ForEach(LiveAccentColor.allCases) { accent in
        Button {
          selection = accent
        } label: {
          Circle()
            .fill(accent.color)
            .frame(width: 28, height: 28)
            .overlay {
              if accent == selection {
                Image(systemName: "checkmark")
                  .font(.system(size: 12, weight: .bold))
                  .foregroundStyle(.white)
              }
            }
            .overlay {
              Circle().strokeBorder(
                DemoTheme.separator.opacity(0.55),
                lineWidth: 0.5
              )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accent.title)
        .accessibilityAddTraits(accent == selection ? .isSelected : [])
        .accessibilityIdentifier("live.settings.appearance.accent.\(accent.id)")
      }
    }
    .padding(.vertical, 8)
    .accessibilityIdentifier("live.settings.appearance.accent")
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
        Toggle("Hide Shorts", isOn: $viewModel.draft.hideShorts).liveRowFill()
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
        ).liveRowFill()
        Toggle(
          "Double-tap to seek",
          isOn: preferences.binding(\.playerDoubleTapSeekEnabled)
        ).liveRowFill()
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
        ).liveRowFill()
        Toggle(
          "Brightness and volume swipe",
          isOn: preferences.binding(
            \.playerSwipeBrightnessVolumeEnabled
          )
        ).liveRowFill()
        Toggle(
          "Long-press to speed up",
          isOn: preferences.binding(\.playerLongPressSpeedEnabled)
        ).liveRowFill()
      } header: {
        Text("Gestures").liveSectionHeader()
      }
      Section {
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
      Section {
        Toggle(
          "Show bullet comments",
          isOn: preferences.binding(\.danmakuEnabled)
        ).liveRowFill()
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
    Section {
      Toggle(
        "Autoplay next video",
        isOn: preferences.binding(\.playerAutoplayEnabled)
      ).liveRowFill()
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
      ).liveRowFill()
      Toggle(
        "Pause in background",
        isOn: preferences.binding(\.playerPauseInBackground)
      ).liveRowFill()
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
