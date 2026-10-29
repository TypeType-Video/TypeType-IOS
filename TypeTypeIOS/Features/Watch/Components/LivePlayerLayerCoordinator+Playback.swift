import AVFoundation
import UIKit

extension LivePlayerLayerCoordinator {
  func observePlaybackIntent() {
    pendingPauseIntentTask?.cancel()
    playbackIntentObservation = nil
    playbackWasIntended =
      controller.player.timeControlStatus == .playing
      || controller.state == .playing
    playbackIntentObservation = controller.player.observe(
      \.timeControlStatus,
      options: [.initial, .new]
    ) { [weak self] player, _ in
      Task { @MainActor [weak self] in
        self?.handlePlaybackStatus(player.timeControlStatus)
      }
    }
  }

  private func handlePlaybackStatus(
    _ status: AVPlayer.TimeControlStatus
  ) {
    switch status {
    case .playing:
      pendingPauseIntentTask?.cancel()
      playbackWasIntended = true
    case .paused:
      if presentationTransitionInProgress, playbackWasIntended {
        schedulePlaybackResume(after: .milliseconds(100))
        return
      }
      let confirmationDelay: Duration =
        isFullScreenPresented ? .seconds(8) : .seconds(1)
      pendingPauseIntentTask?.cancel()
      pendingPauseIntentTask = Task { @MainActor [weak self] in
        do {
          try await Task.sleep(for: confirmationDelay)
        } catch {
          return
        }
        guard let self,
          !presentationTransitionInProgress,
          controller.player.timeControlStatus == .paused
        else {
          return
        }
        playbackWasIntended = false
        fullScreenPlaybackWasIntended = false
      }
    case .waitingToPlayAtSpecifiedRate:
      break
    @unknown default:
      break
    }
  }

  func observeDeviceOrientation() {
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    orientationObservation = NotificationCenter.default.addObserver(
      forName: UIDevice.orientationDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.preservePlaybackAcrossOrientationChange()
      }
    }
  }

  private func preservePlaybackAcrossOrientationChange() {
    guard fullScreenPlaybackWasIntended
      || playbackWasIntended
      || controller.player.timeControlStatus == .playing
      || controller.state == .playing
    else {
      return
    }
    presentationTransitionInProgress = true
    playbackWasIntended = true
    fullScreenPlaybackWasIntended = true
    cancelTransitionTasks()
    schedulePlaybackResume(after: .milliseconds(100))
    settlePlaybackPreservationWindow(
      for: isEndingFullScreen ? .seconds(4) : .milliseconds(800)
    )
  }

  func preservePlayback(
    across coordinator: UIViewControllerTransitionCoordinator
  ) {
    guard fullScreenPlaybackWasIntended
      || playbackWasIntended
      || controller.player.timeControlStatus == .playing
      || controller.state == .playing
    else {
      return
    }
    presentationTransitionInProgress = true
    playbackWasIntended = true
    fullScreenPlaybackWasIntended = true
    cancelTransitionTasks()
    coordinator.animate(alongsideTransition: nil) {
      [weak self] _ in
      guard let self else { return }
      schedulePlaybackResume()
      settlePlaybackPreservationWindow(
        for: isEndingFullScreen ? .seconds(4) : .milliseconds(800)
      )
    }
    schedulePlaybackResume(after: .milliseconds(100))
  }

  func beginPictureInPictureTransition() {
    guard playbackWasIntended
      || controller.player.timeControlStatus == .playing
      || controller.state == .playing
    else {
      return
    }
    presentationTransitionInProgress = true
    playbackWasIntended = true
    cancelTransitionTasks()
  }

  func completePictureInPictureTransition() {
    guard playbackWasIntended else {
      presentationTransitionInProgress = false
      return
    }
    schedulePlaybackResume()
    settlePlaybackPreservationWindow()
  }
}
