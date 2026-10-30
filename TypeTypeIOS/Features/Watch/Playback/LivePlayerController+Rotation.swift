import Foundation

extension LivePlayerController {
  // From the preparation, not nativePlayback: a quality, track or audio-only change drops nativePlayback while it
  // reloads, and full screen would close and reopen around that gap. Before the stream arrives, anything but a live
  // is expected in-house, so a video opened in landscape loads straight into full screen.
  var drawsOwnPlayer: Bool {
    if isOfflineContent { return true }
    if let preparation { return playsNatively(preparation) }
    return !video.isLive && !nativeFallbackUsed
      && UserDefaults.standard.object(forKey: Self.nativePlaybackKey) as? Bool ?? true
  }
}
