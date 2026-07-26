import SwiftUI

struct LiveChannelPodcastsView: View {
  let podcasts: [LivePodcastItem]
  let isLoading: Bool
  let canLoadMore: Bool
  let onSelect: (LivePodcastItem) -> Void
  let onLoadMore: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 11) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Podcasts")
            .font(.headline)
          Text("Podcast playlists from this channel")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if canLoadMore {
          Button(
            isLoading ? "Loading…" : "Load more",
            action: onLoadMore
          )
          .font(.caption.weight(.semibold))
          .disabled(isLoading)
        }
      }

      if isLoading, podcasts.isEmpty {
        ProgressView("Loading podcasts")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 13) {
            ForEach(podcasts) { podcast in
              Button {
                onSelect(podcast)
              } label: {
                VStack(alignment: .leading, spacing: 7) {
                  LiveRemoteImage(
                    url: URL(string: podcast.thumbnailURL)
                  )
                  .frame(width: 130, height: 130)
                  .clipped()
                  .clipShape(
                    RoundedRectangle(cornerRadius: 14)
                  )
                  Text(podcast.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(width: 130, alignment: .leading)
                }
              }
              .buttonStyle(.plain)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
    .accessibilityIdentifier("live.channel.podcasts")
  }
}
