import UIKit

extension LivePlayerController {
  // The native renderer draws its own frames, so nothing keeps the screen awake the way AVPlayer does.
  func updateScreenAwake() {
    let awake = !isTornDown && state == .playing && nativePlayback != nil && !audioOnly
    guard UIApplication.shared.isIdleTimerDisabled != awake else { return }
    UIApplication.shared.isIdleTimerDisabled = awake
    AppLogger.playback.notice("screen kept awake: \(awake, privacy: .public)")
  }
}
