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
  }

  var body: some View {
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
    .onChange(of: preferences.preferences) { newValue in
      DemoTheme.update(
        preferences: newValue,
        colorScheme: systemColorScheme
      )
    }
    .onChange(of: preferences.preferences) { newValue in
      DemoTheme.updateAccent(newValue.accentColor)
    }
    .onChange(of: scenePhase) { phase in
      guard phase == .background,
        preferences.preferences.playerPauseInBackground
      else { return }
      coordinator.dependencies.playbackCoordinator.controller?.pause()
    }
    .preferredColorScheme(
      AppConfig.debugForcesLightAppearance
        ? .light
        : preferences.preferences.appearanceMode.colorScheme
    )
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
