import SwiftUI

struct LiveAuthenticatedAppView: View {
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
        // again — that re-tap is the "back to this tab's input" gesture.
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
  @State var tabBarTopY: CGFloat?
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
    .onChange(of: scenePhase) { phase in
      // Leaving the app with the in-house player active hands the video to
      // the system PiP; returning brings it back to the player page.
      guard let controller = playbackCoordinator.controller,
        controller.nativePlayback != nil
      else { return }
      // .inactive = the resign-active moment: the app's scene still exists
      // here, so the PiP scene creation succeeds; at .background it is
      // already too late and the video degrades to audio-only.
      if phase == .inactive,
        !controller.pictureInPicture.isEngaged,
        playbackCoordinator.hasActivePlayback {
        playbackCoordinator.startSystemPictureInPicture()
      }
      if phase == .active, controller.pictureInPicture.isEngaged {
        controller.pictureInPicture.bringInline()
      }
    }
    .task {
      coordinator.dependencies.playbackService?.preconnectMedia()
      LiveVideoCard.onPrewarm = { video in
        coordinator.dependencies.playbackPrewarmer?.prewarm(video)
      }
      notificationCenter.startPolling()
      LiveBackgroundRefreshCoordinator.shared.scheduleRefresh()
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
        LiveBackgroundRefreshCoordinator.shared.scheduleRefresh()
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
