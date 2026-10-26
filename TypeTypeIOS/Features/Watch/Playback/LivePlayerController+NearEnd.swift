import Foundation

extension LivePlayerController {
  /// The server keeps a prewarmed session for 60 s and the autoplay
  /// countdown takes about 10: the next video is prewarmed inside that window.
  static let nearEndLead: TimeInterval = 40

  func notifyNearEndIfNeeded(at position: TimeInterval) {
    guard duration > 0, !isLiveStream else { return }
    let remaining = duration - position
    if remaining > Self.nearEndLead + 20 {
      // Seeking back re-arms it so the next video is prewarmed again later.
      didNotifyNearEnd = false
      return
    }
    guard !didNotifyNearEnd, remaining <= Self.nearEndLead else { return }
    didNotifyNearEnd = true
    onNearEnd?()
  }
}
