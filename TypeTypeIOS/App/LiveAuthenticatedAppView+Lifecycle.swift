import SwiftUI

extension LiveAuthenticatedAppView {
  @ViewBuilder
  var connectivityBanner: some View {
    if connectivityMonitor.status == .offline || coordinator.isUsingOfflineSession {
      LiveConnectivityBanner(
        instanceUnavailable: coordinator.isUsingOfflineSession,
        onOpenDownloads: { presentsOfflineDownloads = true },
        onRetry: reconnect
      )
    }
  }

  var serviceErrorBinding: Binding<Bool> {
    Binding(
      get: { serviceSelection.errorMessage != nil },
      set: { if !$0 { serviceSelection.dismissError() } }
    )
  }

  func handlePictureInPicture(for phase: ScenePhase) {
    let previousPhase = lastScenePhase
    lastScenePhase = phase
    guard let controller = playbackCoordinator.controller,
      controller.nativePlayback != nil
    else { return }
    // Start PiP on .active to .inactive: at .background it is too late. .background to .inactive is a return.
    if phase == .inactive,
      previousPhase == .active,
      !controller.pictureInPicture.isEngaged,
      playbackCoordinator.hasActivePlayback {
      playbackCoordinator.startSystemPictureInPicture()
    }
    if phase == .active,
      controller.pictureInPicture.isEngaged || controller.pictureInPicture.isSystemActive {
      controller.pictureInPicture.bringInline()
      // A programmatic stop does not always fire the system restore callback: restore the presentation here.
      playbackCoordinator.expand()
    }
  }

  func startSession() async {
    coordinator.dependencies.playbackService?.preconnectMedia()
    if let page = try? await coordinator.dependencies.historyService.history(
      query: nil, from: nil, to: nil, limit: 50, offset: 0
    ) {
      coordinator.dependencies.watchProgress.seed(fromHistory: page)
    }
    notificationCenter.startPolling()
    coordinator.dependencies.backgroundRefresh.scheduleRefresh()
    await applyDefaultLandingPage()
  }

  func openDownloadsForDebugLaunch() {
    #if DEBUG
    if CommandLine.arguments.contains("--typetype-open-downloads") {
      presentsOfflineDownloads = true
    }
    #endif
  }

  func reportActivityWhileVisible() async {
    while !Task.isCancelled {
      try? await coordinator.dependencies.sessionActivityService.report()
      do {
        try await Task.sleep(for: .seconds(60))
      } catch {
        return
      }
    }
  }

  func handleScenePhaseChange() {
    if scenePhase == .active {
      Task {
        try? await coordinator.dependencies.sessionActivityService.report()
        await downloadCenter.activate()
        await coordinator.reconnectIfNeeded()
      }
    } else if scenePhase == .background {
      coordinator.dependencies.backgroundRefresh.scheduleRefresh()
    }
  }

  func handleConnectivityChange() {
    if connectivityMonitor.status == .offline {
      observedConnectivityOutage = true
      return
    }
    guard connectivityMonitor.status == .online, observedConnectivityOutage else { return }
    observedConnectivityOutage = false
    reconnect()
    playbackCoordinator.retryAfterNetworkRecovery()
  }

  func presentPendingIncomingMediaLink() {
    guard incomingMediaLink == nil,
      let link = coordinator.consumeIncomingMediaLink()
    else {
      return
    }
    // Video links go to the player cover only: also pushing the link page opens the video twice.
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
