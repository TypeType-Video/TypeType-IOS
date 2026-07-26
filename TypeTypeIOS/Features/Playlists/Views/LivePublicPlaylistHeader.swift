import SwiftUI

struct LivePublicPlaylistHeader: View {
  let playlist: LivePlaylistResult
  let isSaved: Bool
  let onToggleSaved: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      LiveRemoteImage(url: playlist.thumbnail)
        .aspectRatio(16 / 9, contentMode: .fill)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 5) {
          Text(playlist.title)
            .font(.title2.weight(.bold))
          Text(playlist.uploaderName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Text("\(playlist.streamCount) videos")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        Spacer()
        Button(action: onToggleSaved) {
          Label(
            isSaved ? "Saved" : "Save",
            systemImage: isSaved ? "bookmark.fill" : "bookmark"
          )
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("live.public-playlist.save")
      }
    }
  }
}
