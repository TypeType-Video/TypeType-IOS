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
        // TabView writes the binding even when the active tab is tapped
        // again: that re-tap is the "back to this tab's input" gesture.
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
  @State private var lastScenePhase: ScenePhase = .active
  @State var incomingMediaLink: LiveIncomingMediaLink?
  @State var presentsOfflineDownloads = false
  @State var observedConnectivityOutage = false
  @Environment(\.scenePhase) private var scenePhase

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
    .safeAreaInset(edge: .top, spacing: 0) {
      if connectivityMonitor.status == .offline
        || coordinator.isUsingOfflineSession {
        LiveConnectivityBanner(
          instanceUnavailable: coordinator.isUsingOfflineSession,
          onOpenDownloads: {
            presentsOfflineDownloads = true
          },
          onRetry: reconnect
        )
      }
    }
    .animation(.snappy.delay(0.25), value: playbackCoordinator.showsMiniPlayer)
    .onChange(of: scenePhase) { _, phase in
      // Leaving the app with the in-house player active hands the video to
      // the system PiP; returning brings it back to the player page.
      let previousPhase = lastScenePhase
      lastScenePhase = phase
      guard let controller = playbackCoordinator.controller,
        controller.nativePlayback != nil
      else { return }
      // PiP must start while leaving (.active to .inactive): at .background it is too late. The
      // .background to .inactive step is a return and must not start it.
      if phase == .inactive,
        previousPhase == .active,
        !controller.pictureInPicture.isEngaged,
        playbackCoordinator.hasActivePlayback {
        playbackCoordinator.startSystemPictureInPicture()
      }
      if phase == .active,
        controller.pictureInPicture.isEngaged
          || controller.pictureInPicture.isSystemActive {
        controller.pictureInPicture.bringInline()
        // A programmatic stop does not reliably fire the system's restore
        // callback: bring the presentation back ourselves.
        playbackCoordinator.expand()
      }
    }
    .environment(\.livePrewarm) { video in
      coordinator.dependencies.playbackPrewarmer?.prewarm(video)
    }
    .task {
      coordinator.dependencies.playbackService?.preconnectMedia()
      // Thumbnails draw watch-progress bars from the shared store; seed it
      // at launch so every surface shows them without opening History first.
      if let page = try? await coordinator.dependencies.historyService.history(
        query: nil, from: nil, to: nil, limit: 50, offset: 0
      ) {
        coordinator.dependencies.watchProgress.seed(fromHistory: page)
      }
      notificationCenter.startPolling()
      coordinator.dependencies.backgroundRefresh.scheduleRefresh()
      await applyDefaultLandingPage()
    }
    .onDisappear {
      notificationCenter.stopPolling()
    }
    .task(id: coordinator.identityScopeID) {
      await downloadCenter.activate()
    }
    .task {
      await playbackCoordinator.restoreIfNeeded()
    }
    .task {
      presentPendingIncomingMediaLink()
    }
#if DEBUG
    .task {
      if CommandLine.arguments.contains("--typetype-open-downloads") {
        presentsOfflineDownloads = true
      }
    }
#endif
    .onChange(of: coordinator.pendingIncomingURL) {
      presentPendingIncomingMediaLink()
    }
    .task {
      while !Task.isCancelled {
        try? await coordinator.dependencies.sessionActivityService
          .report()
        do {
          try await Task.sleep(for: .seconds(60))
        } catch {
          return
        }
      }
    }
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        Task {
          try? await coordinator.dependencies.sessionActivityService
            .report()
          await downloadCenter.activate()
          await coordinator.reconnectIfNeeded()
        }
      } else if scenePhase == .background {
        coordinator.dependencies.backgroundRefresh.scheduleRefresh()
      }
    }
    .onChange(of: connectivityMonitor.status) {
      if connectivityMonitor.status == .offline {
        observedConnectivityOutage = true
        return
      }
      guard connectivityMonitor.status == .online,
        observedConnectivityOutage
      else {
        return
      }
      observedConnectivityOutage = false
      reconnect()
      playbackCoordinator.retryAfterNetworkRecovery()
    }
    .alert(
      "Video service",
      isPresented: Binding(
        get: { serviceSelection.errorMessage != nil },
        set: {
          if !$0 {
            serviceSelection.dismissError()
          }
        }
      )
    ) {
      Button("OK") {
        serviceSelection.dismissError()
      }
    } message: {
      Text(
        serviceSelection.errorMessage
          ?? "The default service could not be updated."
      )
    }
    .accessibilityIdentifier("live.authenticated.shell")
  }

  func presentPendingIncomingMediaLink() {
    guard incomingMediaLink == nil,
      let link = coordinator.consumeIncomingMediaLink()
    else {
      return
    }
    // Video links open in the canonical PiP-aware player cover. Presenting
    // the incoming-link page as well slid a second player page in and opened
    // every video twice. Channels and playlists keep the incoming page.
    if case let .video(video) = link.destination {
      playbackCoordinator.open(video)
      return
    }
    incomingMediaLink = link
  }

  func reconnect() {
    Task {
      await coordinator.reconnectIfNeeded()
      await downloadCenter.activate()
      await notificationCenter.refresh()
    }
  }
}
