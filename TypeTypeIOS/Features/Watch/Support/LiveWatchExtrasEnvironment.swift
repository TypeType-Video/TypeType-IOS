import SwiftUI

private struct LiveWatchExtrasEnabledKey: EnvironmentKey {
  static let defaultValue = true
}

extension EnvironmentValues {
  /// False on a watch page until its video has started: library state,
  /// subscriptions, and channel details wait so the video loads first.
  var liveWatchExtrasEnabled: Bool {
    get { self[LiveWatchExtrasEnabledKey.self] }
    set { self[LiveWatchExtrasEnabledKey.self] = newValue }
  }
}
