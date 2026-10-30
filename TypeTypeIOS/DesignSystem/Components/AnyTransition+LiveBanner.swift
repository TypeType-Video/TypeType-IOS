import SwiftUI

extension AnyTransition {
  static func liveBanner(reduceMotion: Bool) -> AnyTransition {
    reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
  }
}
