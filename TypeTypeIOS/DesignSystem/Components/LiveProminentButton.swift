import SwiftUI

private struct LiveProminentButton: ViewModifier {
  @Environment(\.themePalette) private var palette

  func body(content: Content) -> some View {
    content
      .buttonStyle(.borderedProminent)
      .foregroundStyle(palette.onAccent)
  }
}

extension View {
  func liveProminentButton() -> some View {
    modifier(LiveProminentButton())
  }
}
