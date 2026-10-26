import SwiftUI

struct DemoWatchRelatedView: View {
  @EnvironmentObject private var session: DemoSessionStore
  let currentVideoID: String
  let onSelect: (DemoVideo) -> Void
  @Binding var autoplay: Bool
  @State private var visibleLimit = 3
  @State private var isLoadingMore = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Up next")
          .font(.title3.weight(.semibold))
        Spacer()
        Toggle("Autoplay", isOn: $autoplay).liveRowFill()
          .labelsHidden()
        Text("Autoplay")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      LazyVStack(spacing: 11) {
        ForEach(displayedVideos) { video in
          DemoWatchRelatedRow(video: video, onSelect: onSelect)

          if video.id != displayedVideos.last?.id {
            Divider()
              .padding(.leading, 136)
          }
        }

        DemoIncrementalLoadingTrigger(
          canLoadMore: visibleLimit < visibleVideos.count,
          isLoading: isLoadingMore,
          label: "Loading more videos",
          identifier: "demo.watch.related.loading",
          action: loadMore
        )
      }
    }
    .accessibilityIdentifier("demo.watch.related")
  }

  private var visibleVideos: [DemoVideo] {
    DemoWatchCatalog.relatedVideos.filter {
      $0.id != currentVideoID
        && !session.hiddenVideoIDs.contains($0.id)
    }
  }

  private var displayedVideos: [DemoVideo] {
    Array(visibleVideos.prefix(visibleLimit))
  }

  private func loadMore() {
    guard
      visibleLimit < visibleVideos.count,
      !isLoadingMore
    else {
      return
    }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(420))
      withAnimation(.smooth(duration: 0.28)) {
        visibleLimit = min(visibleVideos.count, visibleLimit + 3)
      }
      try? await Task.sleep(for: .milliseconds(180))
      isLoadingMore = false
    }
  }
}
