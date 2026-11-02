import SwiftUI

struct LivePlaylistVideoRow: View {
  let video: LivePlaylistVideo
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  @EnvironmentObject private var watchProgress: LiveWatchProgressStore
  let onOpen: () -> Void
  let onChannel: () -> Void
  let onRemove: () -> Void
  @State private var showsActions = false

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Open video \(branding.title)")
        .liveQuickActionsPress(showsActions: $showsActions, action: onOpen)
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
      LiveQuickActionsDotMenu(isPresented: $showsActions)
        .accessibilityLabel("More actions for \(branding.title)")
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
