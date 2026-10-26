import SwiftUI

struct LiveRelatedVideosSection: View {
  let playerController: LivePlayerController
  let videos: [LiveVideoItem]
  let deArrowStore: LiveDeArrowStore
  let dependencies: AppDependencies
  let onSelect: (LiveVideoItem) -> Void
  @State private var visibleCount = 6

  private var autoplayBinding: Binding<Bool> {
    Binding(
      get: { playerController.autoplayEnabled },
      set: { playerController.setAutoplay($0) }
    )
  }

  var body: some View {
    if !videos.isEmpty {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .center) {
          Text("Up next")
            .font(.title3.weight(.bold))
          Spacer()
          HStack(spacing: 8) {
            Text("Autoplay")
              .font(.subheadline)
              .foregroundStyle(.secondary)
            Toggle("Autoplay", isOn: autoplayBinding).liveRowFill()
              .toggleStyle(.switch)
              .controlSize(.small)
              .labelsHidden()
          }
          .accessibilityIdentifier("live.video.upnext.autoplay")
        }

        LazyVStack(spacing: 14) {
          ForEach(Array(videos.prefix(visibleCount))) { video in
            Button {
              onSelect(video)
            } label: {
              LiveRelatedVideoRow(
                video: video,
                deArrowStore: deArrowStore
              )
            }
            .buttonStyle(.plain)
            .liveVideoQuickActions(
              video: video,
              dependencies: dependencies
            )
            .task(id: video.canonicalID) {
              await Task.yield()
              guard !Task.isCancelled else { return }
              loadMoreIfNeeded(after: video)
            }
          }
        }
      }
      .accessibilityIdentifier("live.player.related")
    }
  }

  private func loadMoreIfNeeded(after video: LiveVideoItem) {
    guard video.canonicalID
      == videos.prefix(visibleCount).last?.canonicalID,
      visibleCount < videos.count
    else {
      return
    }
    visibleCount = min(visibleCount + 6, videos.count)
  }
}

private struct LiveRelatedVideoRow: View {
  let video: LiveVideoItem
  @ObservedObject var deArrowStore: LiveDeArrowStore

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      LiveRemoteImage(url: branding.thumbnailURL)
        .frame(width: 148, height: 148 * 9 / 16)
        .clipped()
        .overlay(alignment: .bottomTrailing) {
          if !video.isLive {
            Text(
              LiveVideoMetadataFormatter.duration(video.duration)
            )
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.black.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(5)
          }
        }
        .clipShape(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
        )

      VStack(alignment: .leading, spacing: 5) {
        Text(branding.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        Text(video.uploaderName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Text(
          [
            LiveVideoMetadataFormatter.views(video.viewCount),
            LiveVideoMetadataFormatter.publication(video),
          ]
          .filter { !$0.isEmpty }
          .joined(separator: " · ")
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .contentShape(Rectangle())
    .task { await deArrowStore.prepare(video) }
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: video)
  }
}
