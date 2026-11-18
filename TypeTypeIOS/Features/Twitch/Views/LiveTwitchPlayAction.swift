import SwiftUI

private struct LiveTwitchPlayKey: EnvironmentKey {
  static let defaultValue: (LiveVideoItem) -> Void = { _ in }
}

private struct LiveTwitchAccountKey: EnvironmentKey {
  static let defaultValue: LiveTwitchAccountServiceProtocol? = nil
}

extension EnvironmentValues {
  var liveTwitchAccount: LiveTwitchAccountServiceProtocol? {
    get { self[LiveTwitchAccountKey.self] }
    set { self[LiveTwitchAccountKey.self] = newValue }
  }

  var liveTwitchPlay: (LiveVideoItem) -> Void {
    get { self[LiveTwitchPlayKey.self] }
    set { self[LiveTwitchPlayKey.self] = newValue }
  }
}
