import SwiftUI

struct LivePlaylistVideoRow: View {
  let video: LivePlaylistVideo
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  @ObservedObject private var watchProgress = LiveWatchProgressStore.shared
  let onOpen: () -> Void
  let onChannel: () -> Void
  let onRemove: () -> Void

  init(
    video: LivePlaylistVideo,
    dependencies: AppDependencies,
    onOpen: @escaping () -> Void,
    onChannel: @escaping () -> Void,
    onRemove: @escaping () -> Void
  ) {
    self.video = video
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    self.onOpen = onOpen
    self.onChannel = onChannel
    self.onRemove = onRemove
  }

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onOpen) {
        LiveRemoteImage(url: branding.thumbnailURL)
          .aspectRatio(16 / 9, contentMode: .fill)
          .frame(width: 128, height: 72)
          .clipped()
          .liveThumbnailProgress(
            watchProgress.fraction(forVideoID: video.url)
          )
          .clipShape(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      VStack(alignment: .leading, spacing: 4) {
        Button(action: onOpen) {
          Text(branding.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
        Button(action: onChannel) {
          Text(video.channelName)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .buttonStyle(.plain)
        .disabled(video.channelURL.isEmpty)
        Text(LiveVideoMetadataFormatter.duration(video.duration))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      Spacer(minLength: 4)
    }
    .contentShape(Rectangle())
    .swipeActions {
      Button("Remove", role: .destructive, action: onRemove)
    }
    .liveVideoQuickActions(
      video: video.video,
      dependencies: dependencies,
      onOpenChannel: onChannel,
      removeLabel: "Remove from playlist",
      onRemove: onRemove
    )
    .accessibilityIdentifier("live.playlist.video")
    .task { await deArrowStore.prepare(video.video) }
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: video.video)
  }
}
