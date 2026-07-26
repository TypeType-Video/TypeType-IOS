import SwiftUI

struct LiveSearchPlaylistCard: View {
  let playlist: LivePlaylistResult
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 9) {
        LiveRemoteImage(url: playlist.thumbnail)
          .frame(maxWidth: .infinity)
          .aspectRatio(16 / 9, contentMode: .fit)
          .clipped()
          .overlay(alignment: .bottomTrailing) {
            Label(
              "\(playlist.streamCount)",
              systemImage: "rectangle.stack.fill"
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.black.opacity(0.8), in: Capsule())
            .padding(7)
          }
          .clipShape(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
          )

        Text(playlist.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
        Text(playlist.uploaderName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.search.playlist")
  }
}
