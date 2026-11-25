import SwiftUI

extension LiveNativePlayerControls {
  var trailingButtons: some View {
    HStack(spacing: 10) {
      AirPlayRouteButton { controls.hold($0) }
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
      if !controller.displayedChapters.isEmpty {
        Button {
          onChapters()
        } label: {
          Image(systemName: "list.bullet.rectangle")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 32, height: 32)
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Chapters")
        .accessibilityIdentifier("live.player.chapters.open")
      }
      Button {
        onFullscreen()
      } label: {
        Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
          .font(.system(size: 15, weight: .semibold))
          .frame(width: 32, height: 32)
          .padding(.horizontal, 8)
          .padding(.vertical, 12)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isFullscreen ? "Exit full screen" : "Full screen")
      .accessibilityIdentifier("live.player.fullscreen-toggle")
    }
  }
}
