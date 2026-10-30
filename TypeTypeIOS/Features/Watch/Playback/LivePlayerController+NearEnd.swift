import Foundation

extension LivePlayerController {
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
