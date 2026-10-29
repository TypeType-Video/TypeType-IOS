import SwiftUI

struct TypeTypeLiveAppView: View {
  @StateObject private var coordinator: RootCoordinator
  @ObservedObject private var preferences: LiveAppPreferencesStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.colorScheme) private var colorScheme

  @MainActor
  init(orientationLock: LiveOrientationLock, backgroundRefresh: LiveBackgroundRefreshCoordinator) {
    self.init(dependencies: .live(orientationLock: orientationLock, backgroundRefresh: backgroundRefresh))
  }

  @MainActor
  init(dependencies: AppDependencies) {
    dependencies.backgroundRefresh.configure(dependencies: dependencies)
    _coordinator = StateObject(
      wrappedValue: RootCoordinator(dependencies: dependencies)
    )
    _preferences = ObservedObject(wrappedValue: dependencies.appPreferences)
    ThemeChrome.installAppearance()
  }

  var body: some View {
    let palette = ThemePalette(
      preferences: preferences.preferences,
      isDark: colorScheme == .dark
    )
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
    .environment(\.themePalette, palette)
    .background(ThemeChromeBridge(chrome: palette.chrome))
    .environmentObject(coordinator.dependencies.watchProgress)
    .environment(\.imagePipeline, coordinator.dependencies.imagePipeline)
    .environmentObject(preferences)
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
    .tint(palette.accent)
    .environment(\.font, preferences.preferences.appearanceFont == .expressive
      ? Font.system(.body, design: .rounded)
      : nil)
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
