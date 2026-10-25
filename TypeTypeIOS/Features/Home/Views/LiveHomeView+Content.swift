import SwiftUI

extension LiveHomeView {
  @ViewBuilder
  var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      loadingView
    case .empty:
      emptyView
    case let .failed(message):
      errorView(message)
    case .loaded:
      feed
    }
  }

  var feed: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 28) {
        if viewModel.showsContinueWatching,
          !viewModel.continueWatching.isEmpty {
          continueWatchingSection
        }

        if viewModel.showsRecommendations {
          recommendationsSection
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 18)
    }
    .background(DemoThemeBackground())
      .liveThemeRepaint()
    .accessibilityIdentifier("live.home.feed")
    .refreshable {
      await viewModel.reload()
    }
  }

  private var recommendationsSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Recommended")
        .font(.headline)

      LazyVGrid(
        columns: [
          GridItem(
            .adaptive(minimum: 330, maximum: 520),
            spacing: 22,
            alignment: .top
          ),
        ],
        alignment: .leading,
        spacing: 24
      ) {
        ForEach(viewModel.videos) { video in
          recommendationCard(video)
        }

        DemoIncrementalLoadingTrigger(
          canLoadMore: viewModel.canLoadMore,
          isLoading: viewModel.isLoadingMore,
          label: "Loading more recommendations",
          identifier: "live.home.loading-more"
        ) {
          Task { await viewModel.loadMore() }
        }
      }
    }
  }

  private func recommendationCard(
    _ video: LiveVideoItem
  ) -> some View {
    LiveVideoCard(
      video: video,
      deArrowStore: coordinator.dependencies.deArrowStore,
      onChannel: {
        guard !video.uploaderURL.isEmpty else { return }
        selectedChannelURL = video.uploaderURL
      },
      action: {
        selectedVideo = video
      }
    )
    .liveVideoQuickActions(
      video: video,
      dependencies: coordinator.dependencies,
      onOpenChannel: {
        guard !video.uploaderURL.isEmpty else { return }
        selectedChannelURL = video.uploaderURL
      }
    )
  }

  private var continueWatchingSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Continue watching")
        .font(.headline)
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 14) {
          ForEach(viewModel.continueWatching) { item in
            LiveHistoryCard(
              item: item,
              dependencies: coordinator.dependencies,
              onSelect: { selectedVideo = item.video },
              onChannel: {
                guard !item.channelURL.isEmpty else { return }
                selectedChannelURL = item.channelURL
              },
              onRemove: {
                Task {
                  await viewModel.removeFromContinueWatching(item)
                }
              }
            )
            .frame(width: 260)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private var loadingView: some View {
    VStack(spacing: 14) {
      ProgressView()
        .controlSize(.large)
      Text("Loading recommendations")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityIdentifier("live.home.loading")
  }

  private var emptyView: some View {
    ContentUnavailableView {
      Label("No recommendations yet", systemImage: "sparkles.tv")
    } description: {
      Text(
        viewModel.showsRecommendations || viewModel.showsContinueWatching
          ? "TypeType will personalize this page as this account watches videos."
          : "Home content is hidden by your TypeType settings."
      )
    } actions: {
      Button("Refresh") {
        Task { await viewModel.reload() }
      }
      .buttonStyle(.borderedProminent)
    }
    .accessibilityIdentifier("live.home.empty")
  }

  private func errorView(_ message: String) -> some View {
    ContentUnavailableView {
      Label("Recommendations unavailable", systemImage: "wifi.exclamationmark")
    } description: {
      Text(message)
    } actions: {
      Button("Try again") {
        Task { await viewModel.reload() }
      }
      .buttonStyle(.borderedProminent)
    }
    .accessibilityIdentifier("live.home.error")
  }
}
