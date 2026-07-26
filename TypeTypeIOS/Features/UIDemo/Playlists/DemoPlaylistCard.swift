import SwiftUI

struct DemoPlaylistCard: View {
  let playlist: DemoPlaylist
  let onSelect: (() -> Void)?

  init(
    playlist: DemoPlaylist,
    onSelect: (() -> Void)? = nil
  ) {
    self.playlist = playlist
    self.onSelect = onSelect
  }

  var body: some View {
    Group {
      if let onSelect {
        Button(action: onSelect) {
          content
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("demo.playlists.card.\(playlist.id)")
      } else {
        content
      }
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 8) {
      ZStack {
        LinearGradient(
          colors: gradientColors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        Circle()
          .fill(.white.opacity(0.08))
          .frame(width: 150, height: 150)
          .offset(x: 62, y: -38)
        Image(playlist.artwork.rawValue)
          .resizable()
          .interpolation(.none)
          .scaledToFit()
          .padding(playlist.artwork == .typeType ? 38 : 20)
          .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        LinearGradient(
          colors: [.clear, .black.opacity(0.4)],
          startPoint: .center,
          endPoint: .bottom
        )
      }
      .aspectRatio(16 / 9, contentMode: .fit)
      .overlay(alignment: .bottomTrailing) {
        Text(videoCount)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 4)
          .background(.black.opacity(0.8))
          .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
          .padding(7)
      }
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

      Text(playlist.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
      Text(playlist.detail)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .contentShape(Rectangle())
  }

  private var videoCount: String {
    playlist.detail.split(separator: "·").first.map(String.init) ?? playlist.detail
  }

  private var gradientColors: [Color] {
    switch playlist.artwork {
    case .television:
      return [Color(red: 0.18, green: 0.22, blue: 0.48), .indigo]
    case .dog:
      return [.orange, Color(red: 0.62, green: 0.16, blue: 0.18)]
    case .cat:
      return [Color(red: 0.55, green: 0.16, blue: 0.42), .purple]
    case .bird:
      return [.cyan, Color(red: 0.05, green: 0.34, blue: 0.64)]
    case .pipePipe:
      return [Color(red: 0.08, green: 0.22, blue: 0.32), .black]
    case .typeType:
      return [Color(red: 0.35, green: 0.09, blue: 0.13), .black]
    }
  }
}
