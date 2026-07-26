import SwiftUI

struct DemoSearchPlaylistRow: View {
  @EnvironmentObject private var session: DemoSessionStore
  let playlist: DemoPlaylist
  let onSelect: () -> Void

  init(
    playlist: DemoPlaylist,
    onSelect: @escaping () -> Void
  ) {
    self.playlist = playlist
    self.onSelect = onSelect
  }

  var body: some View {
    HStack(spacing: 13) {
      Button(action: onSelect) {
        HStack(spacing: 13) {
          ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [
                    Color(red: 0.16, green: 0.17, blue: 0.24),
                    Color.black,
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
            Image(playlist.artwork.rawValue)
              .resizable()
              .interpolation(.none)
              .scaledToFit()
              .padding(13)
          }
          .frame(width: 92, height: 70)

          VStack(alignment: .leading, spacing: 5) {
            Text(playlist.title)
              .font(.subheadline.weight(.semibold))
              .lineLimit(2)
            Label(playlist.detail, systemImage: "play.fill")
              .font(.caption)
              .foregroundStyle(secondaryText)
          }
          .foregroundStyle(primaryText)
          .multilineTextAlignment(.leading)
        }
      }
      .buttonStyle(.plain)

      Spacer(minLength: 4)

      Button {
        withAnimation(.snappy) {
          session.toggleSavedPlaylist(playlist.id)
        }
      } label: {
        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
          .frame(width: 38, height: 38)
          .foregroundStyle(
            isSaved ? Color(red: 1, green: 0.31, blue: 0.34) : primaryText
          )
          .background(actionSurface)
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isSaved ? "Remove saved playlist" : "Save playlist")
    }
    .padding(12)
    .background(cardSurface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .accessibilityIdentifier("demo.search.playlist.\(playlist.id)")
  }

  private var isSaved: Bool {
    session.savedPublicPlaylistIDs.contains(playlist.id)
  }

  private var primaryText: Color {
    .primary
  }

  private var secondaryText: Color {
    .secondary
  }

  private var cardSurface: Color {
    DemoTheme.surface
  }

  private var actionSurface: Color {
    DemoTheme.elevatedSurface
  }
}
