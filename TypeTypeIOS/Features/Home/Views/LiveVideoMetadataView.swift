import SwiftUI

struct LiveVideoMetadataView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  @State private var selectedChannelURL: String?

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        LiveRemoteImage(url: branding.thumbnailURL)
          .frame(maxWidth: .infinity)
          .aspectRatio(16 / 9, contentMode: .fit)
          .clipped()
          .clipShape(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
          )

        VStack(alignment: .leading, spacing: 10) {
          Text(branding.title)
            .font(.title2.weight(.bold))
            .textSelection(.enabled)

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
          }

          if let description = video.shortDescription,
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

        LiveCommentsSectionView(
          videoURL: video.url,
          dependencies: dependencies,
          onChannel: { selectedChannelURL = $0 }
        )

        Label(
          "Playback will be connected in the dedicated player stage.",
          systemImage: "hammer"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          DemoTheme.surface,
          in: RoundedRectangle(cornerRadius: 12)
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
    .accessibilityIdentifier("live.video.metadata")
    .task { await deArrowStore.prepare(video) }
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
}
