import AVFoundation
import Foundation

extension LivePlayerController {
  func installPeriodicObserver() {
    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 1, preferredTimescale: 2),
      queue: .main
    ) { [weak self] time in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let seconds = time.seconds
        guard seconds.isFinite else { return }
        guard nativePlayback == nil else { return }
        handleTimeTick(
          Self.timelinePosition(
            playbackSeconds: seconds,
            offset: playbackTimeOffset,
            duration: duration
          )
        )
      }
    }
  }

  func handleTimeTick(_ currentPosition: TimeInterval) {
    if abs(position - currentPosition) >= 0.05 {
      position = currentPosition
    }
    if preparation?.providerPlayback != nil {
      providerRecoveryResumeTime = max(
        providerRecoveryResumeTime,
        currentPosition
      )
    }
    playbackServer?.updatePlayerTime(currentPosition)
    nativePlayback?.report(currentPosition)
    updateSponsorBlock(at: currentPosition)
    notifyNearEndIfNeeded(at: currentPosition)
    recordHistoryIfNeeded(force: false)
  }

  func setOutputMuted(_ value: Bool) {
    player.isMuted = value
    nativePlayback?.player.isMuted = value
  }

  static func timelinePosition(
    playbackSeconds: TimeInterval,
    offset: TimeInterval,
    duration: TimeInterval
  ) -> TimeInterval {
    let absolutePosition = max(offset, 0) + max(playbackSeconds, 0)
    guard duration.isFinite, duration > 0 else {
      return absolutePosition
    }
    return min(absolutePosition, duration)
  }

  private func updateSponsorBlock(at seconds: TimeInterval) {
    if let sponsorMutedRange {
      if !sponsorMutedRange.contains(seconds) {
        setOutputMuted(settings.muted)
        self.sponsorMutedRange = nil
      } else {
        return
      }
    }
    guard let stream,
      let window = activeSponsorBlockWindow(at: seconds),
      !handledSponsorSegments.contains(window.id),
      LiveSponsorBlockPolicy.shouldAutoSkip(
        window,
        settings: settings,
        streamCategory: stream.category
      )
    else {
      return
    }
    handledSponsorSegments.insert(window.id)
    if settings.sponsorBlockMuteInsteadOfSkip {
      setOutputMuted(true)
      sponsorMutedRange = window.start..<window.end
    } else {
      seek(to: window.end)
    }
  }

  func activeSponsorBlockWindow(
    at seconds: TimeInterval
  ) -> LiveSponsorBlockWindow? {
    visibleSponsorBlockWindows.first {
      seconds >= $0.start && seconds < $0.end
    }
  }

  var visibleSponsorBlockWindows: [LiveSponsorBlockWindow] {
    guard let stream else { return [] }
    return LiveSponsorBlockPolicy.visibleWindows(
      segments: stream.sponsorBlockSegments,
      settings: settings,
      duration: TimeInterval(stream.duration)
    )
  }

  func recordHistoryIfNeeded(force: Bool) {
    guard !settings.disableWatchHistory,
      stream?.isLive != true,
      position > 0
    else {
      return
    }
    let progress = Int64(position.rounded(.down))
    let progressMS = Int64((position * 1_000).rounded())
    guard force || lastHistoryProgress < 0
      || progress - lastHistoryProgress >= 15
    else {
      return
    }
    lastHistoryProgress = progress
    let historyVideo = video.resolving(with: stream)
    let recordsEvent = !didRecordHistoryEvent
    didRecordHistoryEvent = true
    Task { [historyService, historyVideo] in
      do {
        if recordsEvent {
          _ = try await historyService.add(
            video: historyVideo,
            progress: progress
          )
        }
        try await historyService.updateProgress(
          videoURL: historyVideo.url,
          positionMS: progressMS
        )
      } catch {
        AppLogger.network.failure("Saving watch history", error)
      }
    }
  }
}
