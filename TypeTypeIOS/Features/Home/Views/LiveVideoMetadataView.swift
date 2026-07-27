import SwiftUI

struct LiveVideoMetadataView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  @StateObject private var playerController: LivePlayerController
  @State private var selectedChannelURL: String?
  @State private var selectedRelatedVideo: LiveVideoItem?

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
          posterURL: branding.thumbnailURL
        )

        VStack(alignment: .leading, spacing: 10) {
          Text(playerController.stream?.title ?? branding.title)
            .font(.title2.weight(.bold))
            .textSelection(.enabled)

          Button {
            selectedChannelURL = video.uploaderURL
          } label: {
            HStack(spacing: 8) {
              LiveRemoteImage(url: video.uploaderAvatar)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
              VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                  Text(video.uploaderName)
                    .font(.subheadline.weight(.semibold))
                  if video.uploaderVerified {
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
          .disabled(video.uploaderURL.isEmpty)

          if let description = playbackDescription,
            !description.isEmpty {
            Text(description)
              .font(.body)
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }

        LiveVideoLibraryActionsView(
          video: video,
          dependencies: dependencies
        )

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
          videoURL: video.url,
          dependencies: dependencies,
          onChannel: { selectedChannelURL = $0 }
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
    .accessibilityIdentifier("live.video.metadata")
    .task { await deArrowStore.prepare(video) }
    .task { await playerController.loadIfNeeded() }
    .onDisappear { playerController.flushHistory() }
  }

  private var metadata: String {
    var values = [
      LiveVideoMetadataFormatter.views(video.viewCount),
      LiveVideoMetadataFormatter.publication(video),
    ]
    if video.isLive {
      values.insert("Live", at: 0)
    } else {
      values.insert(
        LiveVideoMetadataFormatter.duration(video.duration),
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
}
