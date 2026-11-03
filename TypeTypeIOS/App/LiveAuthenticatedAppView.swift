import SwiftUI

struct LiveAuthenticatedAppView: View {
  @Environment(\.themePalette) var palette
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var serviceSelection: LiveServiceSelection
  @ObservedObject var notificationCenter: LiveNotificationCenter
  @ObservedObject var downloadCenter: LiveDownloadCenter
  @ObservedObject var playbackCoordinator: LivePlaybackCoordinator
  @ObservedObject var connectivityMonitor: LiveConnectivityMonitor
  var selectedTab: Binding<LiveAuthenticatedTab> {
    Binding(
      get: { coordinator.selectedTab },
      set: { newValue in
        // TabView writes the binding even when the active tab is tapped again; that re-tap means back to this tab's
        // input.
        if newValue == coordinator.selectedTab {
          coordinator.handleTabReselection(newValue)
        } else {
          coordinator.selectedTab = newValue
        }
      }
    )
  }
  @State var librarySection = LiveLibrarySection.history
  @State var didApplyDefaultLandingPage = false
  @State var presentsExpandedPlayback = false
  @State var lastScenePhase: ScenePhase = .active
  @State var incomingMediaLink: LiveIncomingMediaLink?
  @State var presentsOfflineDownloads = false
  @State var observedConnectivityOutage = false
  @Environment(\.scenePhase) var scenePhase

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    serviceSelection = coordinator.dependencies.serviceSelection
    notificationCenter = coordinator.dependencies.notificationCenter
    downloadCenter = coordinator.dependencies.downloadCenter
    playbackCoordinator = coordinator.dependencies.playbackCoordinator
    connectivityMonitor = coordinator.dependencies.connectivityMonitor
  }

  var body: some View {
    shell
      .safeAreaInset(edge: .top, spacing: 0) { connectivityBanner }
      .animation(.snappy.delay(0.25), value: playbackCoordinator.showsMiniPlayer)
      .onChange(of: scenePhase) { _, phase in handlePictureInPicture(for: phase) }
      .environment(\.livePrewarm) { video in
        coordinator.dependencies.playbackPrewarmer?.prewarm(video)
      }
      .environment(\.liveSettledPrefetch, coordinator.dependencies.playbackPrewarmer?.settledCards)
      .task { await startSession() }
      .onDisappear { notificationCenter.stopPolling() }
      .task(id: coordinator.identityScopeID) { await downloadCenter.activate() }
      .task { await playbackCoordinator.restoreIfNeeded() }
      .task { presentPendingIncomingMediaLink() }
      .task { openDownloadsForDebugLaunch() }
      .onChange(of: coordinator.pendingIncomingURL) { presentPendingIncomingMediaLink() }
      .task { await reportActivityWhileVisible() }
      .onChange(of: scenePhase) { handleScenePhaseChange() }
      .onChange(of: connectivityMonitor.status) { handleConnectivityChange() }
      .alert("Video service", isPresented: serviceErrorBinding) {
        Button("OK") { serviceSelection.dismissError() }
      } message: {
        Text(serviceSelection.errorMessage ?? String(localized: "The default service could not be updated."))
      }
      .modifier(LiveSettingsPresentation(coordinator: coordinator))
      .accessibilityIdentifier("live.authenticated.shell")
  }
}
