import SwiftUI

struct DemoWatchCommentsView: View {
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void
  @State private var sort = "Top"
  @State private var visibleCount = 3
  @State private var isLoadingMore = false

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 18) {
      HStack {
        Text("Comments")
          .font(.title3.weight(.semibold))
        Text("\(DemoWatchCatalog.comments.count)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Menu {
          Picker("Comment order", selection: $sort) {
            Text("Top comments").tag("Top")
            Text("Newest first").tag("Newest")
          }
        } label: {
          Label(sort, systemImage: "arrow.up.arrow.down")
            .font(.caption.weight(.semibold))
        }
      }

      ForEach(visibleComments) { comment in
        DemoWatchCommentRow(
          comment: comment,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
      }

      DemoIncrementalLoadingTrigger(
        canLoadMore: visibleCount < sortedComments.count,
        isLoading: isLoadingMore,
        label: "Loading more comments",
        identifier: "demo.watch.comments.loading",
        action: loadMore
      )
    }
    .foregroundStyle(.primary)
    .accessibilityIdentifier("demo.watch.comments")
    .onChange(of: sort) {
      visibleCount = 3
      isLoadingMore = false
    }
  }

  private var visibleComments: [DemoWatchComment] {
    Array(sortedComments.prefix(visibleCount))
  }

  private var sortedComments: [DemoWatchComment] {
    sort == "Newest"
      ? Array(DemoWatchCatalog.comments.reversed())
      : DemoWatchCatalog.comments
  }

  private func loadMore() {
    guard !isLoadingMore, visibleCount < sortedComments.count else { return }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(380))
      withAnimation(.smooth(duration: 0.25)) {
        visibleCount = min(visibleCount + 3, sortedComments.count)
      }
      try? await Task.sleep(for: .milliseconds(140))
      isLoadingMore = false
    }
  }
}
