import SwiftUI

private struct LivePrewarmKey: EnvironmentKey {
  static let defaultValue: ((LiveVideoItem) -> Void)? = nil
}

private struct LiveSettledPrefetchKey: EnvironmentKey {
  static let defaultValue: LiveSettledCardPrefetch? = nil
}

extension EnvironmentValues {
  var liveSettledPrefetch: LiveSettledCardPrefetch? {
    get { self[LiveSettledPrefetchKey.self] }
    set { self[LiveSettledPrefetchKey.self] = newValue }
  }

  var livePrewarm: ((LiveVideoItem) -> Void)? {
    get { self[LivePrewarmKey.self] }
    set { self[LivePrewarmKey.self] = newValue }
  }
}
