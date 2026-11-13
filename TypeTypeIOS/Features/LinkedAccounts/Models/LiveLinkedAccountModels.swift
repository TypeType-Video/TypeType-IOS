import Foundation

struct LiveYouTubeDeviceLogin: Decodable, Equatable {
  let userCode: String
  let verificationURL: String
  let interval: Duration

  init(userCode: String, verificationURL: String, interval: Duration) {
    self.userCode = userCode
    self.verificationURL = verificationURL
    self.interval = interval
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    userCode = try values.decode(String.self, forKey: .userCode)
    verificationURL = try values.decode(String.self, forKey: .verificationURL)
    let seconds = try values.decodeIfPresent(Int.self, forKey: .intervalSeconds) ?? 5
    interval = .seconds(min(max(seconds, 2), 30))
  }

  private enum CodingKeys: String, CodingKey {
    case userCode, intervalSeconds
    case verificationURL = "verificationUrl"
  }
}

enum LiveYouTubeDevicePoll: Equatable {
  case pending
  case slowDown
  case connected

  init(status: String) {
    switch status {
    case "connected": self = .connected
    case "slow_down": self = .slowDown
    default: self = .pending
    }
  }
}

enum LiveBiliBiliSessionState: Equatable {
  case connected
  case needsReconnect
  case disconnected

  init(status: String) {
    switch status {
    case "connected": self = .connected
    case "needs_reconnect": self = .needsReconnect
    default: self = .disconnected
    }
  }
}

struct LiveBiliBiliQRLogin: Decodable, Equatable {
  let qrURL: String
  let qrcodeKey: String

  private enum CodingKeys: String, CodingKey {
    case qrcodeKey
    case qrURL = "qrUrl"
  }
}

enum LiveBiliBiliQRPoll: Equatable {
  case waiting
  case scanned
  case confirmed
  case expired
  case failed

  init(status: String) {
    switch status {
    case "waiting": self = .waiting
    case "scanned": self = .scanned
    case "confirmed": self = .confirmed
    case "expired": self = .expired
    default: self = .failed
    }
  }
}
