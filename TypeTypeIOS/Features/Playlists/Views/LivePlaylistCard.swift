import SwiftUI

struct LivePlaylistCard: View {
  let playlist: LivePlaylist
  let onOpen: () -> Void
  let onDelete: () -> Void

  var body: some View {
    Button(action: onOpen) {
      VStack(alignment: .leading, spacing: 9) {
        ZStack(alignment: .bottomTrailing) {
          Color.clear
            .aspectRatio(16 / 10, contentMode: .fit)
            .overlay {
              LiveRemoteImage(
                url: URL(string: playlist.videos.first?.thumbnail ?? "")
              )
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .clipped()
            }
            .clipShape(
              RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
          Text(String(playlist.videoCount))
            .font(.caption.weight(.semibold))
            .frame(minWidth: 28)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
          .background(.black.opacity(0.78), in: Capsule())
          .foregroundStyle(.white)
          .padding(8)
        }
        Text(playlist.name)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(2)
        if !playlist.description.isEmpty {
          Text(playlist.description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button("Open", systemImage: "rectangle.stack", action: onOpen)
      Button(
        "Delete",
        systemImage: "trash",
        role: .destructive,
        action: onDelete
      )
    }
    .accessibilityIdentifier("live.playlists.card")
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(playlist.name), \(playlist.videoCount) videos")
  }
}
