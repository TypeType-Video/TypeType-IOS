import SwiftUI

struct LivePlaybackQueueView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  @State private var presentsQueue = false

  var body: some View {
    if coordinator.queue.isActive {
      Button {
        presentsQueue = true
      } label: {
        HStack(spacing: 13) {
          Image(systemName: "text.line.first.and.arrowtriangle.forward")
            .font(.title3)
            .foregroundStyle(.tint)
            .frame(width: 42, height: 42)
            .background(.tint.opacity(0.14), in: Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text(
              coordinator.queue.title.isEmpty
                ? "Playback queue"
                : coordinator.queue.title
            )
            .font(.headline)
            .lineLimit(1)
            Text(
              "\(coordinator.queue.currentIndex + 1) of "
                + "\(coordinator.queue.videos.count)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(14)
        .background(
          DemoTheme.surface,
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
      }
      .buttonStyle(.plain)
      .sheet(isPresented: $presentsQueue) {
        LivePlaybackQueueSheet(coordinator: coordinator)
      }
      .accessibilityIdentifier("live.playback.queue")
    }
  }
}
