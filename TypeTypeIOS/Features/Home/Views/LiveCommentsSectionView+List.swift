import SwiftUI

extension LiveCommentsSectionView {
  var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      TextField("Search comments", text: $search.query)
        .submitLabel(.search)
        .autocorrectionDisabled()
        .onSubmit { Task { await search.search() } }
        .accessibilityIdentifier("live.comments.search")
      if !search.query.isEmpty || search.isActive {
        Button {
          search.clear()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear the comment search")
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
  }

  @ViewBuilder
  var searchResults: some View {
    switch search.state {
    case .idle:
      EmptyView()
    case .searching:
      ProgressView()
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Searching the comments")
    case .empty:
      Text("No comment matches this search.")
        .foregroundStyle(.secondary)
    case let .failed(message):
      Text(message)
        .foregroundStyle(.secondary)
    case .results:
      rows(search.results, canLoadMore: search.canLoadMore, isLoading: search.isLoadingMore) {
        Task { await search.loadMore() }
      }
    }
  }

  var commentList: some View {
    rows(viewModel.comments, canLoadMore: viewModel.canLoadMore, isLoading: viewModel.isLoadingMore) {
      Task { await viewModel.loadMore() }
    }
  }

  // A plain stack: a lazy one rebuilds rows of different heights on the way back up and the page jumps.
  private func rows(
    _ comments: [LiveCommentItem],
    canLoadMore: Bool,
    isLoading: Bool,
    loadMore: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      ForEach(comments) { comment in
        LiveCommentRow(
          comment: comment,
          threads: threads,
          voice: voice,
          animatesGIFs: dependencies.appPreferences.preferences.commentsAnimateGIFs,
          onChannel: onChannel,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
        Divider()
      }
      LiveIncrementalLoadingTrigger(
        canLoadMore: canLoadMore,
        isLoading: isLoading,
        label: "Loading more comments",
        identifier: "live.comments.loading-more",
        action: loadMore
      )
    }
  }
}
