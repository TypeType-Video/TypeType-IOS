import SwiftUI

extension View {
  @ViewBuilder
  func liveStartupProbe(_ milliseconds: Int?) -> some View {
    #if DEBUG
    overlay(alignment: .topLeading) {
      Color.clear
        .frame(width: 1, height: 1)
        .accessibilityElement()
        .accessibilityIdentifier("live.player.startup")
        .accessibilityValue(milliseconds.map(String.init) ?? "")
    }
    #else
    self
    #endif
  }
}
