import Foundation

enum DebugNetworkOutage {
  #if DEBUG
  private static let launchedAt = Date()
  private static let window: Range<TimeInterval>? = {
    guard let value = ProcessInfo.processInfo.environment["TT_DEBUG_OUTAGE"] else { return nil }
    let parts = value.split(separator: ":").compactMap { TimeInterval($0) }
    guard parts.count == 2, parts[1] > 0 else { return nil }
    return parts[0]..<(parts[0] + parts[1])
  }()
  #endif

  static func check() throws {
    #if DEBUG
    if let window, window.contains(Date().timeIntervalSince(launchedAt)) {
      throw URLError(.notConnectedToInternet)
    }
    #endif
  }
}
