import SwiftUI

struct LiveSavedPlaylistCard: View {
  let playlist: LiveSavedPlaylist
  let onOpen: () -> Void
  let onRemove: () -> Void

  var body: some View {
    Button(action: onOpen) {
      VStack(alignment: .leading, spacing: 8) {
        ZStack(alignment: .bottomTrailing) {
          LiveRemoteImage(url: playlist.thumbnail)
            .aspectRatio(16 / 10, contentMode: .fill)
            .frame(width: 190)
            .clipped()
            .clipShape(
              RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
          Label(
            String(playlist.streamCount),
            systemImage: "rectangle.stack.fill"
          )
          .font(.caption2.weight(.semibold))
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(.black.opacity(0.78), in: Capsule())
          .foregroundStyle(.white)
          .padding(7)
        }
        Text(playlist.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
        Text(playlist.uploaderName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(width: 190, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button(
        "Remove from library",
        systemImage: "bookmark.slash",
        role: .destructive,
        action: onRemove
      )
    }
    .accessibilityIdentifier("live.saved-playlist.card")
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(playlist.title), \(playlist.streamCount) videos")
  }
}
