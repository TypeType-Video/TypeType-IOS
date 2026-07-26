import Foundation

struct LiveYouTubeSessionStatus: Decodable, Equatable {
  let status: String
  let updatedAt: Int64
  let lastUsedAt: Int64

  var isConnected: Bool {
    status == "connected"
  }
}

struct LiveYouTubeRemoteBrowserSession: Decodable, Equatable {
  let sessionID: String
  let webSocketURL: String
  let expiresAt: Int64

  private enum CodingKeys: String, CodingKey {
    case sessionID = "sessionId"
    case webSocketURL = "wsUrl"
    case expiresAt
  }
}

enum LiveYouTubeRemotePhase: String {
  case idle
  case connecting
  case opening
  case awaitingLogin = "awaiting_login"
  case capturingSession = "capturing_session"
  case connected
  case closed
  case error

  var title: String {
    rawValue.replacingOccurrences(of: "_", with: " ").capitalized
  }
}

struct LiveYouTubeRemoteStartPayload: Encodable {
  let returnTo: String?
}
