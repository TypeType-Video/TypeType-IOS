import SwiftUI

struct LibraryPlaylistRowView: View {
  let playlist: PlaylistSummary

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(playlist.name)
        .font(.headline)
        .lineLimit(1)
      if !playlist.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(playlist.description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      Text("\(playlist.videos.count) videos")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 4)
  }
}
