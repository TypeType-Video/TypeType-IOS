import ActivityKit
import AppIntents
import Foundation

/// Shared between the app and the widget extension: the Live Activity
/// payload plus the intents the Dynamic Island buttons perform.
struct PlaybackActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var channelName: String
    var thumbnailURL: String?
    var isPlaying: Bool
    var positionMilliseconds: Int64
    var durationMilliseconds: Int64?
  }
}

/// The system delivers the button intents to the app process; the playback
/// coordinator registers its handlers here so the Island drives the real
/// player instead of a detached stub.
final class PlaybackActivityBridge {
  static let shared = PlaybackActivityBridge()

  var onToggle: (() -> Void)?
  var onNext: (() -> Void)?
  var onPrevious: (() -> Void)?
}

struct PlaybackToggleIntent: LiveActivityIntent {
  static var isDiscoverable: Bool = false
  static var title: LocalizedStringResource = "Play or pause"

  func perform() async throws -> some IntentResult {
    await MainActor.run { PlaybackActivityBridge.shared.onToggle?() }
    return .result()
  }
}

struct PlaybackNextIntent: LiveActivityIntent {
  static var isDiscoverable: Bool = false
  static var title: LocalizedStringResource = "Next video"

  func perform() async throws -> some IntentResult {
    await MainActor.run { PlaybackActivityBridge.shared.onNext?() }
    return .result()
  }
}

struct PlaybackPreviousIntent: LiveActivityIntent {
  static var isDiscoverable: Bool = false
  static var title: LocalizedStringResource = "Previous video"

  func perform() async throws -> some IntentResult {
    await MainActor.run { PlaybackActivityBridge.shared.onPrevious?() }
    return .result()
  }
}
