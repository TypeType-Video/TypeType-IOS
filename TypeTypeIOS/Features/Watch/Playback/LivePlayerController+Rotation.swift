import Foundation

extension LivePlayerController {
  // From the preparation, not nativePlayback: a quality, track or audio-only change drops nativePlayback while it
  // reloads, and full screen would close and reopen around that gap.
  var drawsOwnPlayer: Bool {
    isOfflineContent || preparation.map(playsNatively) == true
  }
}
