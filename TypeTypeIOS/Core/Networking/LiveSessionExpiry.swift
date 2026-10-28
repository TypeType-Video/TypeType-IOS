import Foundation

enum LiveSessionExpiry {
  static let serverIDKey = "serverID"
}

extension Notification.Name {
  // The server refused the refresh token itself: the session is over, not just a stale access token.
  static let liveSessionExpired = Notification.Name("dev.typetype.session-expired")
}
