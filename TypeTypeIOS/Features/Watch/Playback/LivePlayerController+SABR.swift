import AVFoundation
import Foundation

extension LivePlayerController {
  func scheduleSABRRecoveryBudgetReset(
    for item: AVPlayerItem
  ) {
    guard preparation?.isSABR == true,
      sabrStallRecoveryCount > 0
    else {
      return
    }
    sabrRecoveryBudgetResetTask?.cancel()
    sabrRecoveryBudgetResetTask = Task {
      @MainActor [weak self, weak item] in
      do {
        try await Task.sleep(for: .seconds(
          Self.sabrRecoveryBudgetResetDelay
        ))
      } catch {
        return
      }
      guard let self, let item,
        player.currentItem === item,
        player.timeControlStatus == .playing,
        preparation?.isSABR == true
      else {
        return
      }
      sabrStallRecoveryCount = 0
      sabrRecoveryBudgetResetTask = nil
    }
  }

  func scheduleSABRStallRecovery(
    for item: AVPlayerItem
  ) {
    guard preparation?.isSABR == true,
      providerRecoveryDesiredAutoplay,
      sabrStallRecoveryCount < Self.maximumSABRStallRecoveries
    else {
      return
    }
    sabrStallRecoveryTask?.cancel()
    sabrStallRecoveryTask = Task { @MainActor [weak self, weak item] in
      do {
        try await Task.sleep(for: .seconds(
          Self.sabrStallRecoveryDelay
        ))
      } catch {
        return
      }
      guard let self, let item,
        player.currentItem === item,
        player.timeControlStatus == .waitingToPlayAtSpecifiedRate,
        preparation?.isSABR == true,
        providerRecoveryDesiredAutoplay
      else {
        return
      }
      sabrStallRecoveryTask = nil
      recoverSABRFromStall()
    }
  }

  func recoverSABRFromStall() {
    guard let service, let stream,
      preparation?.isSABR == true,
      sabrStallRecoveryCount < Self.maximumSABRStallRecoveries
    else {
      return
    }
    sabrStallRecoveryCount += 1
    let restartTime = max(position, 0)
    state = .loading
    AppLogger.app.info(
      "Recovering stalled SABR playback at \(restartTime, privacy: .public)s (attempt \(self.sabrStallRecoveryCount, privacy: .public))."
    )
    loadTask?.cancel()
    loadTask = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let recoveredPreparation = try service.prepare(
          stream: stream,
          sourceURL: video.url,
          preferences: preferences
        )
        guard !Task.isCancelled else { return }
        resetProviderRecoveryState(
          for: recoveredPreparation,
          autoplay: true
        )
        try await installWithProviderFallback(
          recoveredPreparation,
          autoplay: true,
          seekOverride: restartTime
        )
      } catch is CancellationError {
        return
      } catch {
        Self.logPreparationFailure(error)
        state = .failed(Self.message(for: error))
        stopPlaybackSession()
      }
    }
  }

  func seekSABR(
    to seconds: TimeInterval,
    autoplay: Bool?
  ) {
    guard let playbackServer else { return }
    seekTask?.cancel()
    let shouldAutoplay = autoplay
      ?? (
        providerRecoveryDesiredAutoplay
          || player.timeControlStatus == .playing
          || state == .playing
      )
    state = .loading
    seekTask = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let assetURL = try await playbackServer.seekSABR(to: seconds)
        try Task.checkCancellation()
        playbackTimeOffset = playbackServer.sabrPlaybackStartTime
        position = seconds
        pendingSeek = playbackTimeOffset == 0 ? seconds : nil
        installPlayerItem(
          at: assetURL,
          autoplay: shouldAutoplay
        )
        reportPlaybackSessionProgress()
      } catch is CancellationError {
        return
      } catch {
        state = player.timeControlStatus == .playing
          ? .playing
          : .paused
      }
    }
  }

  private static let sabrStallRecoveryDelay: TimeInterval = 12
  private static let sabrRecoveryBudgetResetDelay: TimeInterval = 30
  private static let maximumSABRStallRecoveries = 2
}
