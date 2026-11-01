import AVFoundation
import Foundation

extension LivePlayerController {
  static let airPlayStartBudget = Duration.seconds(20)

  // The native player only sends sound over AirPlay. With a receiver chosen, playback moves to AVPlayer,
  // served on the Wi-Fi address so the receiver fetches the video itself; it moves back once the route ends.
  func observeAirPlayRoute() {
    airPlay.routeObservation = NotificationCenter.default
      .publisher(for: AVAudioSession.routeChangeNotification)
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        MainActor.assumeIsolated { self?.airPlayRouteChanged() }
      }
  }

  // AVPlayer keeps the TypeType controls over an AirPlay route, as it does for downloads: AVKit's own would
  // fight our gestures for every tap.
  var drawsOwnControls: Bool {
    nativePlayback != nil || isOfflineContent || airPlay.isActive
  }

  var playbackServerHost: String {
    guard airPlay.isActive else { return LivePlaybackHTTPServer.loopbackHost }
    return LiveLocalNetworkAddress.wifiIPv4() ?? LivePlaybackHTTPServer.loopbackHost
  }

  // A receiver that cannot reach the device must not end playback: the native player resumes, sending sound only.
  func abandonAirPlayHandoff(reason: String) -> Bool {
    guard airPlay.isActive else { return false }
    AppLogger.playback.error("airplay: video handoff failed, back to sound only: \(reason, privacy: .public)")
    setAirPlayPhase(.refused)
    airPlay.watchdog?.cancel()
    restartAtCurrentPosition(autoplay: true)
    return true
  }

  private func airPlayRouteChanged() {
    let routeIsAirPlay = AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .airPlay }
    guard routeIsAirPlay else {
      let wasActive = airPlay.isActive
      setAirPlayPhase(.off)
      airPlay.watchdog?.cancel()
      if wasActive {
        AppLogger.playback.info("airplay: route ended, back to the native player")
        restartAtCurrentPosition(autoplay: player.timeControlStatus == .playing)
      }
      return
    }
    guard airPlay.phase == .off, nativePlayback != nil, !audioOnly,
      LiveLocalNetworkAddress.wifiIPv4() != nil
    else {
      return
    }
    AppLogger.playback.info("airplay: moving playback to AVPlayer")
    setAirPlayPhase(.active)
    restartAtCurrentPosition(autoplay: state == .playing)
    armAirPlayWatchdog()
  }

  private func armAirPlayWatchdog() {
    airPlay.watchdog?.cancel()
    airPlay.watchdog = Task { [weak self] in
      try? await Task.sleep(for: Self.airPlayStartBudget)
      guard !Task.isCancelled, let self, airPlay.isActive else { return }
      switch state {
      case .ready, .playing, .paused:
        return
      case .idle, .loading, .failed:
        _ = abandonAirPlayHandoff(reason: "the receiver did not start in time")
      }
    }
  }

  private func setAirPlayPhase(_ phase: LiveAirPlayHandoff.Phase) {
    guard airPlay.phase != phase else { return }
    objectWillChange.send()
    airPlay.phase = phase
  }
}
