import SwiftUI

struct LivePlaybackQueueRow: View {
  let video: LiveVideoItem
  let isCurrent: Bool
  let onPlay: () -> Void
  let onPlayNext: () -> Void
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onPlay) {
        HStack(spacing: 12) {
          thumbnail
          metadata
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(isCurrent)

      if !isCurrent {
        LiveDotMenu {
          Button("Play next", systemImage: "text.insert") {
            onPlayNext()
          }
          Button("Remove", systemImage: "trash", role: .destructive) {
            onRemove()
          }
        }
        .accessibilityLabel("Queue options")
      }
    }
    .listRowBackground(
      isCurrent ? DemoTheme.accent.opacity(0.1) : Color.clear
    )
  }

  private var thumbnail: some View {
    LiveRemoteImage(url: video.thumbnail)
      .frame(width: 96, height: 54)
      .aspectRatio(16 / 9, contentMode: .fill)
      .clipped()
      .clipShape(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
      )
      .overlay {
        if isCurrent {
          Image(systemName: "play.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(7)
            .background(DemoTheme.accent, in: Circle())
        }
      }
  }

  private var metadata: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(video.title)
        .font(
          .subheadline.weight(
            isCurrent ? .semibold : .regular
          )
        )
        .foregroundStyle(.primary)
        .lineLimit(2)
      Text(video.uploaderName)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
