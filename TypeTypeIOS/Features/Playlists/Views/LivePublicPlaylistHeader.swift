import SwiftUI

struct LivePublicPlaylistHeader: View {
  let playlist: LivePlaylistResult
  let isSaved: Bool
  let isPreparingPlayback: Bool
  let onPlayAll: () -> Void
  let onShuffle: () -> Void
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
        .liveProminentButton()
        .accessibilityIdentifier("live.public-playlist.save")
      }
      HStack(spacing: 12) {
        Button(action: onPlayAll) {
          Label("Play all", systemImage: "play.fill")
            .frame(maxWidth: .infinity)
        }
        .liveProminentButton()
        .disabled(isPreparingPlayback)

        Button(action: onShuffle) {
          Label("Shuffle", systemImage: "shuffle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isPreparingPlayback)
      }
      .overlay {
        if isPreparingPlayback {
          ProgressView()
            .padding(8)
            .background(.regularMaterial, in: Circle())
        }
      }
    }
  }
}
