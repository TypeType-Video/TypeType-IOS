import AVFoundation
import Foundation

extension LivePlayerController {
  func startPlaybackSessionIfNeeded() {
    guard let snapshot = playbackActivitySnapshot else { return }
    playbackSessionReporter.startIfNeeded(snapshot)
    startPlaybackSessionProgressLoop()
  }

  func reportPlaybackSessionProgress() {
    guard let snapshot = playbackActivitySnapshot else { return }
    if state == .playing {
      playbackSessionReporter.startIfNeeded(snapshot)
    }
    playbackSessionReporter.progress(snapshot)
  }

  private func startPlaybackSessionProgressLoop() {
    guard playbackSessionProgressTask == nil else { return }
    playbackSessionProgressTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .seconds(15))
        } catch {
          return
        }
        guard let self else { return }
        reportPlaybackSessionProgress()
      }
    }
  }

  func stopPlaybackSession() {
    playbackSessionProgressTask?.cancel()
    playbackSessionProgressTask = nil
    playbackSessionReporter.stop()
  }

  private var playbackActivitySnapshot:
    LivePlaybackActivitySnapshot? {
    let resolvedVideo = video.resolving(with: stream)
    guard let stream,
      !stream.isLive,
      !stream.isLiveContent,
      !resolvedVideo.url.isEmpty,
      !resolvedVideo.title.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).isEmpty
    else {
      return nil
    }
    let resolvedDuration = duration.isFinite && duration > 0
      ? duration
      : TimeInterval(resolvedVideo.duration)
    return LivePlaybackActivitySnapshot(
      videoURL: resolvedVideo.url,
      title: resolvedVideo.title,
      thumbnailURL: resolvedVideo.thumbnailURL.isEmpty
        ? nil
        : resolvedVideo.thumbnailURL,
      channelName: resolvedVideo.uploaderName.isEmpty
        ? nil
        : resolvedVideo.uploaderName,
      positionMilliseconds: milliseconds(position),
      durationMilliseconds: resolvedDuration > 0
        ? milliseconds(resolvedDuration)
        : nil,
      isPaused: player.timeControlStatus == .paused
    )
  }

  private func milliseconds(
    _ seconds: TimeInterval
  ) -> Int64 {
    guard seconds.isFinite, seconds > 0 else { return 0 }
    return Int64(
      min(seconds * 1_000, Double(Int64.max)).rounded(.down)
    )
  }
}
