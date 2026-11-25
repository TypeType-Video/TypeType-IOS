import AVFoundation

extension LivePlayerController {
  var offersTwitchAudioOnly: Bool {
    stream?.twitchMedia?.audioURL != nil
  }

  func handleTwitchLiveStall(for item: AVPlayerItem) {
    guard preparation?.stream.twitchMedia != nil, preparation?.stream.isLive == true else { return }
    twitchLive.stalled { [weak self, weak item] in
      guard let self, let item else { return false }
      // AVPlayer can drop from waiting to paused on a live that ran dry: both count as stalled.
      return player.currentItem === item && player.timeControlStatus != .playing && self.state == .loading
    } reload: { [weak self] in
      guard let self else { return }
      AppLogger.playback.notice("twitch live stalled, reloading attempt \(self.twitchLive.attempts, privacy: .public)")
      retry()
    }
  }

  // Watching a live saves the matching position of the recording it makes, so opening that later goes on from there.
  func recordTwitchArchiveProgress(_ archive: LiveTwitchArchive, force: Bool) {
    guard !settings.disableWatchHistory, twitchLive.savesRecordingPosition, position > 0 else { return }
    let progress = Int64(position.rounded(.down))
    guard force || lastHistoryProgress < 0 || progress - lastHistoryProgress >= 30,
      let archivePosition = LiveTwitchArchiveTime.position(startedAt: archive.startedAt, now: Date())
    else { return }
    lastHistoryProgress = progress
    let url = LiveTwitchPlayback.url(for: .video(archive.id))
    Task { [historyService] in
      do {
        try await historyService.updateProgress(videoURL: url, positionMS: Int64(archivePosition * 1_000))
      } catch {
        AppLogger.network.failure("Saving the Twitch recording position", error)
      }
    }
  }

  // The recording resumes at the saved position: saving the chosen moment first opens it right there.
  func prepareTwitchRewind(_ archive: LiveTwitchArchive, to position: TimeInterval) async -> LiveVideoItem {
    twitchLive.savesRecordingPosition = false
    AppLogger.playback.notice("twitch: rewind into the recording at \(Int(position), privacy: .public) s")
    let link = LiveTwitchLink.video(archive.id)
    do {
      try await historyService.updateProgress(videoURL: LiveTwitchPlayback.url(for: link), positionMS: Int64(position * 1_000))
    } catch {
      AppLogger.network.failure("Saving the Twitch rewind position", error)
    }
    guard let live = stream?.twitchMedia?.live else { return LiveTwitchPlayback.item(for: link) }
    return LiveTwitchPlayback.item(recordingOf: live, archive: archive)
  }
}
