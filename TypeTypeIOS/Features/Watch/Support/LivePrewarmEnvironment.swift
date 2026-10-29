import SwiftUI

private struct LivePrewarmKey: EnvironmentKey {
  static let defaultValue: ((LiveVideoItem) -> Void)? = nil
}

extension EnvironmentValues {
  var livePrewarm: ((LiveVideoItem) -> Void)? {
    get { self[LivePrewarmKey.self] }
    set { self[LivePrewarmKey.self] = newValue }
  }
}
