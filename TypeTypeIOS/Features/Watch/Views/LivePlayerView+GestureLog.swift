import Foundation

extension LivePlayerView {
  nonisolated(unsafe) static var gestureLog: [String] = []

  static func logGesture(_ text: String) {
    #if DEBUG
    gestureLog.insert(text, at: 0)
    if gestureLog.count > 4 { gestureLog.removeLast() }
    AppLogger.playback.info("gesture: \(text, privacy: .public)")
    #endif
  }
}
