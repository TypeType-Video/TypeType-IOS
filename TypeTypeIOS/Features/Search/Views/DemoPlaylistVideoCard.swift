import SwiftUI

struct DemoPlaylistVideoCard: View {
  @Environment(\.themePalette) private var palette
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  let onSelect: () -> Void
  let onRemove: () -> Void
  let onMoveEarlier: () -> Void
  let onMoveLater: () -> Void
  let showsReorderActions: Bool

  init(
    video: DemoVideo,
    onSelect: @escaping () -> Void,
    onRemove: @escaping () -> Void,
    onMoveEarlier: @escaping () -> Void = {},
    onMoveLater: @escaping () -> Void = {},
    showsReorderActions: Bool = false
  ) {
    self.video = video
    self.onSelect = onSelect
    self.onRemove = onRemove
    self.onMoveEarlier = onMoveEarlier
    self.onMoveLater = onMoveLater
    self.showsReorderActions = showsReorderActions
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Button(action: onSelect) {
        DemoArtworkView(video: displayVideo)
          .frame(width: 146, height: 82)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
      .buttonStyle(.plain)

      Button(action: onSelect) {
        VStack(alignment: .leading, spacing: 4) {
          Text(displayVideo.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          Text(video.channel)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text(video.metadata)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)

      Menu {
        Button("Play", systemImage: "play.fill", action: onSelect)
        if showsReorderActions {
          Button(
            "Move earlier",
            systemImage: "arrow.up",
            action: onMoveEarlier
          )
          Button(
            "Move later",
            systemImage: "arrow.down",
            action: onMoveLater
          )
        }
        Button(
          "Remove",
          systemImage: "xmark",
          role: .destructive,
          action: onRemove
        )
      } label: {
        Image(systemName: "ellipsis")
          .foregroundStyle(.secondary)
          .frame(width: 30, height: 30)
      }
    }
    .padding(10)
    .background(palette.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }
}
