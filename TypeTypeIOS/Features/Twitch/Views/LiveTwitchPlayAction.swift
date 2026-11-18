import SwiftUI

private struct LiveTwitchPlayKey: EnvironmentKey {
  static let defaultValue: (LiveVideoItem) -> Void = { _ in }
}

extension EnvironmentValues {
  var liveTwitchPlay: (LiveVideoItem) -> Void {
    get { self[LiveTwitchPlayKey.self] }
    set { self[LiveTwitchPlayKey.self] = newValue }
  }
}
