import SwiftUI

struct DemoChannelVideosSection: View {
  let videos: [DemoVideo]
  let query: String
  let sortOrder: String
  let canLoadMore: Bool
  let onSelect: (DemoVideo) -> Void
  let onLoadMore: () -> Void
  @State private var isLoadingMore = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      heading

      if videos.isEmpty {
        ContentUnavailableView.search
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
      } else {
        LazyVStack(spacing: 12) {
          ForEach(videos) { video in
            DemoCompactVideoRow(
              video: video,
              identifier: "demo.channel.video.\(video.id)",
              showsChannel: false,
              onSelect: onSelect
            )

            if video.id != videos.last?.id {
              Divider()
                .padding(.leading, 158)
            }
          }

          DemoIncrementalLoadingTrigger(
            canLoadMore: canLoadMore,
            isLoading: isLoadingMore,
            label: "Loading more channel videos",
            identifier: "demo.channel.videos.loading",
            action: loadMore
          )
        }
      }
    }
    .accessibilityIdentifier("demo.channel.recommended")
  }

  private var heading: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(query.isEmpty ? sectionTitle : "Search results")
        .font(.title3.weight(.bold))
      Text(
        query.isEmpty
          ? "Sorted \(sortOrder.lowercased())"
          : "\(videos.count) results for “\(query)”"
      )
      .font(.caption)
      .foregroundStyle(.secondary)
    }
  }

  private var sectionTitle: String {
    switch sortOrder {
    case "Popular":
      return "Popular videos"
    case "Oldest":
      return "Oldest videos"
    default:
      return "Latest videos"
    }
  }

  private func loadMore() {
    guard canLoadMore, !isLoadingMore else { return }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(380))
      onLoadMore()
      try? await Task.sleep(for: .milliseconds(140))
      isLoadingMore = false
    }
  }
}
