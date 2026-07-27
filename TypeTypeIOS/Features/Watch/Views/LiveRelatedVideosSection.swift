import SwiftUI

struct LiveRelatedVideosSection: View {
  let videos: [LiveVideoItem]
  let deArrowStore: LiveDeArrowStore
  let onSelect: (LiveVideoItem) -> Void
  @State private var visibleCount = 6

  var body: some View {
    if !videos.isEmpty {
      VStack(alignment: .leading, spacing: 14) {
        Text("Up next")
          .font(.title3.weight(.bold))

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
            .onAppear {
              loadMoreIfNeeded(after: video)
            }
          }
        }
      }
      .accessibilityIdentifier("live.player.related")
      .onChange(of: videos.map(\.canonicalID)) {
        visibleCount = min(6, videos.count)
      }
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
        .frame(width: 148)
        .aspectRatio(16 / 9, contentMode: .fit)
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
