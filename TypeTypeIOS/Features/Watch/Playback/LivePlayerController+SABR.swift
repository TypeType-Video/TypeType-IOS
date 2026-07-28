import AVFoundation
import Foundation

extension LivePlayerController {
  func seekSABR(
    to seconds: TimeInterval,
    autoplay: Bool?
  ) {
    guard let playbackServer else { return }
    seekTask?.cancel()
    let shouldAutoplay = autoplay
      ?? (player.timeControlStatus == .playing || state == .playing)
    state = .loading
    seekTask = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let assetURL = try await playbackServer.seekSABR(to: seconds)
        try Task.checkCancellation()
        playbackTimeOffset = playbackServer.sabrPlaybackStartTime
        position = seconds
        pendingSeek = nil
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
}
