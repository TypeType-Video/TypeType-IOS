import SwiftUI

struct LiveChannelPostsView: View {
  @StateObject private var viewModel: LiveChannelPostsViewModel
  let onOpenURL: (URL) -> Void

  init(channelURL: String, service: LiveChannelServiceProtocol, onOpenURL: @escaping (URL) -> Void) {
    _viewModel = StateObject(wrappedValue: LiveChannelPostsViewModel(channelURL: channelURL, service: service))
    self.onOpenURL = onOpenURL
  }

  var body: some View {
    content
      .task { await viewModel.load() }
      .accessibilityIdentifier("live.channel.posts")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .loading:
      TypeTypeSkeletonList(layout: .cards, count: 2, scrolls: false)
    case .empty:
      ContentUnavailableView("No posts", systemImage: "text.bubble", description: Text("This channel has not posted anything."))
        .liveThemedEmptyState()
        .padding(.vertical, 50)
    case let .failed(message):
      ContentUnavailableView {
        Label("Posts unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") { Task { await viewModel.load() } }
      }
    case .loaded:
      LazyVStack(alignment: .leading, spacing: 14) {
        ForEach(viewModel.posts) { post in
          LiveCommunityPostCard(
            post: post,
            onOpenVideo: { link in URL(string: link).map(onOpenURL) },
            onOpenURL: onOpenURL
          )
        }
        LiveIncrementalLoadingTrigger(
          canLoadMore: viewModel.canLoadMore,
          isLoading: viewModel.isLoadingMore,
          label: "Loading more posts",
          identifier: "live.channel.posts.loading-more"
        ) {
          Task { await viewModel.loadMore() }
        }
      }
    }
  }
}
