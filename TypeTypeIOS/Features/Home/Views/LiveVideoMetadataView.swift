import SwiftUI

struct LiveVideoMetadataView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  @StateObject private var playerController: LivePlayerController
  @State private var selectedChannelURL: String?
  @State private var selectedRelatedVideo: LiveVideoItem?
  @State private var selectedPublicPlaylist: LivePlaylistResult?
  @State private var pendingExternalURL: URL?

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    _playerController = StateObject(
      wrappedValue: LivePlayerController(
        video: video,
        dependencies: dependencies
      )
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        LivePlayerView(
          controller: playerController,
          posterURL: posterURL
        )

        VStack(alignment: .leading, spacing: 10) {
          Text(playerController.stream?.title ?? branding.title)
            .font(.title2.weight(.bold))
            .textSelection(.enabled)

          Button {
            selectedChannelURL = resolvedVideo.uploaderURL
          } label: {
            HStack(spacing: 8) {
              LiveRemoteImage(url: resolvedVideo.uploaderAvatar)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
              VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                  Text(resolvedVideo.uploaderName)
                    .font(.subheadline.weight(.semibold))
                  if resolvedVideo.uploaderVerified {
                    Image(systemName: "checkmark.seal.fill")
                      .font(.caption)
                      .foregroundStyle(DemoTheme.accent)
                      .accessibilityLabel("Verified")
                  }
                }
                Text(metadata)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            }
          }
          .buttonStyle(.plain)
          .disabled(resolvedVideo.uploaderURL.isEmpty)

          if let description = playbackDescription,
            !description.isEmpty {
            InteractiveText(
              text: description,
              font: .body,
              lineLimit: nil,
              onSeekTimestamp: playerController.seek,
              onOpenURL: routeLink
            )
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }

        LiveVideoLibraryActionsView(
          video: resolvedVideo,
          dependencies: dependencies
        )
        .id(libraryActionsIdentity)

        if let stream = playerController.stream,
          !stream.chapters.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            Text("Chapters")
              .font(.title3.weight(.bold))
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 10) {
                ForEach(stream.chapters) { chapter in
                  Button {
                    playerController.seek(
                      to: TimeInterval(chapter.startTimeSeconds)
                    )
                  } label: {
                    VStack(alignment: .leading, spacing: 3) {
                      Text(chapter.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                      Text(
                        LiveVideoMetadataFormatter.duration(
                          Int64(chapter.startTimeSeconds)
                        )
                      )
                      .font(.caption.monospacedDigit())
                      .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(
                      DemoTheme.surface,
                      in: RoundedRectangle(cornerRadius: 12)
                    )
                  }
                  .buttonStyle(.plain)
                }
              }
            }
          }
        }

        if let related = playerController.stream?.relatedStreams {
          LiveRelatedVideosSection(
            videos: related.filter { !$0.isShortFormContent },
            deArrowStore: deArrowStore,
            onSelect: { selectedRelatedVideo = $0 }
          )
        }

        LiveCommentsSectionView(
          videoURL: resolvedVideo.url,
          dependencies: dependencies,
          onChannel: { selectedChannelURL = $0 },
          onSeekTimestamp: playerController.seek,
          onOpenURL: routeLink
        )
      }
      .padding(16)
    }
    .background(DemoTheme.background)
    .navigationTitle("Video")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(
      item: $selectedChannelURL
    ) { channelURL in
      LiveChannelView(
        channelURL: channelURL,
        dependencies: dependencies
      )
    }
    .navigationDestination(
      item: $selectedRelatedVideo
    ) { relatedVideo in
      LiveVideoMetadataView(
        video: relatedVideo,
        dependencies: dependencies
      )
    }
    .navigationDestination(
      item: $selectedPublicPlaylist
    ) { playlist in
      LivePublicPlaylistView(
        playlist: playlist,
        dependencies: dependencies
      )
    }
    .externalLinkAlert(pendingURL: $pendingExternalURL)
    .accessibilityIdentifier("live.video.metadata")
    .task(id: libraryActionsIdentity) {
      await deArrowStore.prepare(resolvedVideo)
    }
    .task { await playerController.loadIfNeeded() }
    .onDisappear { playerController.flushHistory() }
  }

  private var metadata: String {
    var values = [
      LiveVideoMetadataFormatter.views(resolvedVideo.viewCount),
      LiveVideoMetadataFormatter.publication(resolvedVideo),
    ]
    if resolvedVideo.isLive {
      values.insert("Live", at: 0)
    } else {
      values.insert(
        LiveVideoMetadataFormatter.duration(resolvedVideo.duration),
        at: 0
      )
    }
    return values.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: video)
  }

  private var playbackDescription: String? {
    let full = playerController.stream?.description
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if let full, !full.isEmpty { return full }
    return video.shortDescription
  }

  private var posterURL: URL? {
    guard let value = playerController.stream?.thumbnailURL,
      let url = URL(string: value)
    else {
      return branding.thumbnailURL
    }
    return url
  }

  private var resolvedVideo: LiveVideoItem {
    guard let stream = playerController.stream else { return video }
    return LiveVideoItem(
      id: stream.id.isEmpty ? video.id : stream.id,
      title: stream.title.isEmpty ? video.title : stream.title,
      url: video.url,
      thumbnailURL: stream.thumbnailURL.isEmpty
        ? video.thumbnailURL
        : stream.thumbnailURL,
      uploaderName: stream.uploaderName.isEmpty
        ? video.uploaderName
        : stream.uploaderName,
      uploaderURL: stream.uploaderURL.isEmpty
        ? video.uploaderURL
        : stream.uploaderURL,
      uploaderAvatarURL: stream.uploaderAvatarURL.isEmpty
        ? video.uploaderAvatarURL
        : stream.uploaderAvatarURL,
      duration: stream.duration > 0 ? stream.duration : video.duration,
      viewCount: stream.viewCount > 0
        ? stream.viewCount
        : video.viewCount,
      uploadDate: video.uploadDate,
      uploaded: video.uploaded,
      streamType: video.streamType.isEmpty
        ? "VIDEO_STREAM"
        : video.streamType,
      isShortFormContent: false,
      uploaderVerified: video.uploaderVerified,
      shortDescription: playbackDescription,
      publishedAt: video.publishedAt,
      isLive: stream.isLive,
      isPostLive: stream.isPostLive,
      isLiveContent: stream.isLiveContent,
      requiresMembership: video.requiresMembership
    )
  }

  private var libraryActionsIdentity: String {
    [
      resolvedVideo.canonicalID,
      resolvedVideo.title,
      resolvedVideo.uploaderName,
    ].joined(separator: ":")
  }

  private func routeLink(_ url: URL) {
    switch LiveMediaLinkResolver.destination(for: url) {
    case let .video(linkedVideo):
      selectedRelatedVideo = linkedVideo
    case let .channel(channelURL):
      selectedChannelURL = channelURL
    case let .playlist(playlist):
      selectedPublicPlaylist = playlist
    case nil:
      pendingExternalURL = url
    }
  }
}
