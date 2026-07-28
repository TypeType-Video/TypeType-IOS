import Foundation

enum AppConfig {
  static let serverListKey = "typetype.server-list"
  static let selectedServerIDKey = "typetype.selected-server-id"
  static let sessionRegistryKey = "typetype.session-registry"
  static let playbackQueueRegistryKey = "typetype.playback-queue-registry"
  static let accessTokenService = "dev.typetype.ios.access-token"
  static let keychainTokenPrefix = "typetype.token"
  static let defaultAPIPath = "/api"

  static var debugIncomingURL: URL? {
#if DEBUG
    guard let index = CommandLine.arguments.firstIndex(
      of: "--typetype-open-url"
    ), CommandLine.arguments.indices.contains(index + 1)
    else {
      return nil
    }
    return URL(string: CommandLine.arguments[index + 1])
#else
    return nil
#endif
  }

  static var debugForcesLightAppearance: Bool {
#if DEBUG
    CommandLine.arguments.contains(
      "--typetype-force-light-appearance"
    )
#else
    false
#endif
  }
}
