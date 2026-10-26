import SwiftUI

struct TypeTypeLiveAppView: View {
  @StateObject private var coordinator: RootCoordinator
  @ObservedObject private var preferences = LiveAppPreferencesStore.shared
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.colorScheme) private var systemColorScheme

  @MainActor
  init() {
    self.init(dependencies: .live())
  }

  @MainActor
  init(dependencies: AppDependencies) {
    LiveBackgroundRefreshCoordinator.shared.configure(
      dependencies: dependencies
    )
    _coordinator = StateObject(
      wrappedValue: RootCoordinator(dependencies: dependencies)
    )
    DemoTheme.update(preferences: preferences.preferences)
    DemoTheme.applyUIKitAppearance(preferences.preferences)
  }

  var body: some View {
    // Runs BEFORE every render pass: updating in onChange rendered stale
    // colors first and needed a second tap to show. The environment scheme
    // also makes system light/dark changes apply immediately.
    let _ = applyTheme()
    let palette = DemoTheme.palette()
    Group {
      switch coordinator.state {
      case .booting:
        LiveLaunchView()
      case .serverSetup:
        ServerSetupView(coordinator: coordinator)
      case .authentication:
        LiveAuthView(coordinator: coordinator)
      case .authenticated:
        LiveAuthenticatedAppView(coordinator: coordinator)
          .id(coordinator.identityScopeID)
      }
    }
    .environment(\.demoTheme, palette)
    .id(themeIdentity)
    .task {
      if let launchURL = AppConfig.debugIncomingURL {
        coordinator.receiveIncomingURL(launchURL)
      }
      await coordinator.bootstrap()
    }
    .onOpenURL(perform: coordinator.receiveIncomingURL)
    .animation(
      preferences.preferences.appearanceMotion == .off
        ? nil
        : .easeInOut(
          duration: preferences.preferences.appearanceMotion.duration ?? 0.16
        ),
      value: coordinator.state
    )
    .tint(preferences.preferences.accentColor.color)
    .environment(\.font, preferences.preferences.appearanceFont == .expressive
      ? Font.system(.body, design: .rounded)
      : nil)
    .onChange(of: preferences.preferences) {
      applyTheme()
    }
    .onChange(of: colorScheme) { _, _ in
      applyTheme()
    }
    .onChange(of: scenePhase) {
      guard scenePhase == .background,
        preferences.preferences.playerPauseInBackground
      else { return }
      coordinator.dependencies.playbackCoordinator.controller?.pause()
    }
    .preferredColorScheme(
      AppConfig.debugForcesLightAppearance
        ? .light
        : preferredColorScheme
    )
  }

  @Environment(\.colorScheme) private var colorScheme

  private func applyTheme() {
    DemoTheme.update(
      preferences: preferences.preferences,
      colorScheme: colorScheme
    )
    DemoTheme.applyUIKitAppearance(preferences.preferences)
  }

  private var themeIdentity: String {
    let value = preferences.preferences
    return [
      // The system scheme is part of the identity: a system light/dark flip
      // rebuilds the whole hierarchy so no stale fragments survive.
      colorScheme == .dark ? "sysDark" : "sysLight",
      value.accentColor.rawValue,
      value.appearancePersonality.rawValue,
      value.appearanceMode.rawValue,
      value.appearanceAmoled.description,
      value.appearanceTheme.rawValue,
      value.appearanceFont.rawValue,
      value.appearanceMotion.rawValue,
      value.mangaPaper.rawValue,
      value.mangaHeadlineMarker.rawValue,
      value.mangaScreentone.description,
      value.mangaSpeedLines.description,
      value.mangaStarburst.description,
      value.mangaInkedIcons.description,
      value.mangaPanelTilt.description,
    ].joined(separator: "|")
  }

  private var preferredColorScheme: ColorScheme? {
    if AppConfig.debugForcesLightAppearance { return .light }
    switch preferences.preferences.appearanceMode {
    case .light: return .light
    case .dark: return .dark
    case .system:
      return nil
    }
  }
}

private struct LiveLaunchView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      VStack(spacing: 18) {
        Image("TypeTypeLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 92, height: 92)
        ProgressView()
          .tint(.white)
      }
    }
    .preferredColorScheme(.dark)
  }
}
