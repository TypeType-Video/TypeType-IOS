import SwiftUI

struct LiveAuthenticatedAppView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var serviceSelection: LiveServiceSelection
  @ObservedObject var notificationCenter: LiveNotificationCenter
  @ObservedObject var downloadCenter: LiveDownloadCenter
  @ObservedObject var playbackCoordinator: LivePlaybackCoordinator
  @ObservedObject var connectivityMonitor: LiveConnectivityMonitor
  @State var selectedTab = LiveAuthenticatedTab.home
  @State var startupCollection: LiveLibraryCollectionKind?
  @State var didApplyDefaultLandingPage = false
  @State var presentsSearch = false
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
    .animation(.snappy, value: presentsSearch)
    .task {
      coordinator.dependencies.playbackService?.preconnectMedia()
      LiveVideoCard.onPrewarm = { video in
        Task {
          guard let service = coordinator.dependencies.playbackService else {
            return
          }
          // Only what starting playback needs; full metadata follows on open.
          _ = try? await service.playbackStream(for: video.url)
        }
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
