import SwiftUI

extension View {
  /// Startup time for the local benchmark, read through accessibility in
  /// debug builds; never shown, and absent from release builds.
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
