import Foundation

extension LivePlayerController {
  // The server keeps a prewarm for 60 s and the countdown takes about 10: prewarm inside that window.
  static let nearEndLead: TimeInterval = 40

  func notifyNearEndIfNeeded(at position: TimeInterval) {
    guard duration > 0, !isLiveStream else { return }
    let remaining = duration - position
    if remaining > Self.nearEndLead + 20 {
      didNotifyNearEnd = false
      return
    }
    guard !didNotifyNearEnd, remaining <= Self.nearEndLead else { return }
    didNotifyNearEnd = true
    onNearEnd?()
  }
}
