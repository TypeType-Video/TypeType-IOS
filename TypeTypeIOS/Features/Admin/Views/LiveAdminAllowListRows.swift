import SwiftUI

struct LiveAdminAllowedChannelRow: View {
  let item: LiveContentControlItem

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(item.name ?? "Channel")
        .font(.headline)
      Text(item.url)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
  }
}

struct LiveAdminAllowedPlaylistRow: View {
  let item: LiveAllowedPlaylistItem

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(item.title ?? "Playlist")
        .font(.headline)
      if let uploader = item.uploaderName {
        Text(uploader)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Text(item.url)
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .lineLimit(2)
    }
  }
}
