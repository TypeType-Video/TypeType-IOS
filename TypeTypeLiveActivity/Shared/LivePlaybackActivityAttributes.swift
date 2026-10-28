import ActivityKit
import Foundation

/// Shared between the app and the Live Activity widget extension — compiled
/// into both targets (see project.yml: the extension takes the whole
/// TypeTypeLiveActivity folder, the app only this Shared folder).
struct LivePlaybackActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var title: String
    var channel: String
    var isPlaying: Bool
    /// 0...1 playback position for the progress line.
    var progress: Double
  }

  var videoURL: String
}
