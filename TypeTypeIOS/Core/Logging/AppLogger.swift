import OSLog

enum AppLogger {
  static let app = Logger(subsystem: "dev.typetype.ios", category: "app")
  static let auth = Logger(subsystem: "dev.typetype.ios", category: "auth")
  static let network = Logger(subsystem: "dev.typetype.ios", category: "network")
  static let playback = Logger(subsystem: "dev.typetype.ios", category: "playback")
}
