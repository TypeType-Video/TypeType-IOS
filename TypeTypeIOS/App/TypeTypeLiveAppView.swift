import SwiftUI

struct TypeTypeLiveAppView: View {
  @StateObject private var coordinator: RootCoordinator

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
    .animation(.easeInOut(duration: 0.22), value: coordinator.state)
    .preferredColorScheme(
      AppConfig.debugForcesLightAppearance ? .light : nil
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
