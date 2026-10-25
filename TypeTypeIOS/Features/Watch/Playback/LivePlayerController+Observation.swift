import AVFoundation
import Foundation

extension LivePlayerController {
  func observe(
    _ item: AVPlayerItem,
    autoplay: Bool
  ) {
    if let endObservation {
      NotificationCenter.default.removeObserver(endObservation)
    }
    endObservation = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(100))
        guard let self else { return }
        state = .paused
        recordHistoryIfNeeded(force: true)
        reportPlaybackSessionProgress()
        stopPlaybackSession()
        if loopsPlayback {
          replay()
        } else {
          onPlaybackEnded?()
        }
      }
    }
    itemObservation = item.observe(
      \.status,
      options: [.initial, .new]
    ) { [weak self] item, _ in
      Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(100))
        guard let self, player.currentItem === item else { return }
        handleStatus(item, autoplay: autoplay)
      }
    }
    playbackObservation = player.observe(
      \.timeControlStatus,
      options: [.new]
    ) { [weak self] player, _ in
      Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(100))
        guard let self else { return }
        switch player.timeControlStatus {
        case .paused:
          sabrStallRecoveryTask?.cancel()
          sabrStallRecoveryTask = nil
          sabrRecoveryBudgetResetTask?.cancel()
          sabrRecoveryBudgetResetTask = nil
          if state == .playing {
            state = .paused
            reportPlaybackSessionProgress()
          }
        case .waitingToPlayAtSpecifiedRate:
          sabrRecoveryBudgetResetTask?.cancel()
          sabrRecoveryBudgetResetTask = nil
          if state != .loading {
            state = .loading
          }
          scheduleSABRStallRecovery(for: item)
        case .playing:
          sabrStallRecoveryTask?.cancel()
          sabrStallRecoveryTask = nil
          if state != .playing {
            state = .playing
          }
          scheduleSABRRecoveryBudgetReset(for: item)
          startPlaybackSessionIfNeeded()
        @unknown default:
          break
        }
      }
    }
  }

  private func handleStatus(
    _ item: AVPlayerItem,
    autoplay: Bool
  ) {
    switch item.status {
    case .unknown:
      if state != .loading {
        state = .loading
      }
    case .readyToPlay:
      let resolvedDuration: TimeInterval
      if preparation?.isSABR == true {
        resolvedDuration = TimeInterval(
          preparation?.stream.duration ?? 0
        )
      } else {
        resolvedDuration = item.duration.seconds.isFinite
          ? item.duration.seconds
          : TimeInterval(preparation?.stream.duration ?? 0)
      }
      if duration != resolvedDuration {
        duration = resolvedDuration
      }
      configureSubtitles(for: item)
      resume(item, autoplay: autoplay)
    case .failed:
      let failure = State.failed(
        DemoPlaybackErrorFormatter.message(for: item.error)
      )
      if state != failure {
        state = failure
      }
      stopPlaybackSession()
    @unknown default:
      let failure = State.failed(
        "The player reported an unknown state."
      )
      if state != failure {
        state = failure
      }
    }
  }

  private func resume(
    _ item: AVPlayerItem,
    autoplay: Bool
  ) {
    guard !isTornDown else { return }
    let target = pendingSeek ?? 0
    pendingSeek = nil
    guard target > 0 else {
      if autoplay {
        playIfActive()
      } else if state != .ready {
        state = .ready
      }
      return
    }
    player.seek(
      to: CMTime(seconds: target, preferredTimescale: 600),
      toleranceBefore: .zero,
      toleranceAfter: .zero
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(100))
        guard let self else { return }
        if autoplay {
          playIfActive()
        } else if state != .ready {
          state = .ready
        }
      }
    }
  }

  func configureSubtitles(for item: AVPlayerItem) {
    let enablesSubtitles = subtitlesEnabled
    let language = selectedSubtitleLanguage
    item.textStyleRules = LiveCaptionTextStyleRuleBuilder.rules(
      for: settings.captionStyles
    )
    Task { [weak self, weak item] in
      guard let self, let item else { return }
      guard let group = try? await item.asset.loadMediaSelectionGroup(
        for: .legible
      ) else {
        return
      }
      guard player.currentItem === item else { return }
      if !enablesSubtitles {
        item.select(nil, in: group)
        return
      }
      let option = group.options.first(where: { option in
        guard !language.isEmpty else { return false }
        return option.extendedLanguageTag?.lowercased().hasPrefix(
          language.lowercased()
        ) == true
      }) ?? group.defaultOption ?? group.options.first
      item.select(option, in: group)
    }
  }
}
