import SwiftUI

private struct LiveWatchExtrasEnabledKey: EnvironmentKey {
  static let defaultValue = true
}

extension EnvironmentValues {
  var liveWatchExtrasEnabled: Bool {
    get { self[LiveWatchExtrasEnabledKey.self] }
    set { self[LiveWatchExtrasEnabledKey.self] = newValue }
  }
}
