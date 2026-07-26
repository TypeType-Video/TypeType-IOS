import SwiftUI

struct DemoPlaybackQueueRow: View {
  @EnvironmentObject private var session: DemoSessionStore
  let index: Int
  let video: DemoVideo
  let count: Int
  let onSelect: () -> Void

  var body: some View {
    HStack(spacing: 11) {
      Button(action: onSelect) {
        HStack(spacing: 11) {
          Text("\(index + 1)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 18)
          DemoArtworkView(video: displayVideo)
            .frame(width: 82, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          VStack(alignment: .leading, spacing: 3) {
            Text(displayVideo.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)
              .lineLimit(2)
            Text(video.channel)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Menu {
        Button("Move up", systemImage: "arrow.up") {
          session.moveQueuedVideo(video.id, offset: -1)
        }
        .disabled(index == 0)
        Button("Move down", systemImage: "arrow.down") {
          session.moveQueuedVideo(video.id, offset: 1)
        }
        .disabled(index == count - 1)
        Button("Remove", systemImage: "trash", role: .destructive) {
          session.toggleQueue(video.id)
        }
      } label: {
        Image(systemName: "ellipsis")
          .frame(width: 36, height: 40)
      }
      .accessibilityLabel("Queue actions for \(video.title)")
    }
    .swipeActions(edge: .trailing) {
      Button("Remove", role: .destructive) {
        session.toggleQueue(video.id)
      }
    }
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }
}
