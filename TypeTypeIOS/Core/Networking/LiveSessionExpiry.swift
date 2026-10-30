import Foundation

enum LiveSessionExpiry {
  static let serverIDKey = "serverID"
}

extension Notification.Name {
  static let liveSessionExpired = Notification.Name("dev.typetype.session-expired")
}
