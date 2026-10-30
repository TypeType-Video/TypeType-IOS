import SwiftUI

struct DemoHistoryRow: View {
  @Environment(\.themePalette) private var palette
  @EnvironmentObject private var session: DemoSessionStore
  let entry: DemoHistoryEntry
  let onSelect: () -> Void
  let onRemove: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Button(action: onSelect) {
        DemoArtworkView(video: displayVideo)
          .frame(width: 148, height: 84)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
      .buttonStyle(.plain)

      Button(action: onSelect) {
        VStack(alignment: .leading, spacing: 5) {
          Text(displayVideo.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          Text(entry.video.channel)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text(entry.watchedAt)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)

      Menu {
        Button("Remove from history", systemImage: "trash", role: .destructive) {
          onRemove()
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 30, height: 30)
          .background(palette.elevatedSurface)
          .clipShape(Circle())
      }
      .accessibilityLabel("History actions for \(entry.video.title)")
    }
    .padding(10)
    .background(palette.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .accessibilityIdentifier("demo.history.video.\(entry.id)")
  }

  private var displayVideo: DemoVideo {
    entry.video.branded(using: session.preferences)
  }
}
