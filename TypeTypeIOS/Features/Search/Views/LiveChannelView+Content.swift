import SwiftUI

extension LiveChannelView {
  var content: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        if let channel = viewModel.channel {
          LiveChannelHeaderView(
            channel: channel,
            isSubscribed: viewModel.isSubscribed,
            isChangingSubscription:
              viewModel.isChangingSubscription
            isNotificationsAvailable:
              viewModel.isNotificationsAvailable,
            isNotificationsEnabled:
              viewModel.isNotificationsEnabled,
            isChangingNotifications:
              viewModel.isChangingNotifications,
            onNotifications: {
              Task { await viewModel.toggleNotifications() }
            },
            onSubscription: {
              Task { await viewModel.toggleSubscription() }
            }
          )
        }

        if viewModel.selectedTab == .videos,
          viewModel.isLoadingPodcasts || !viewModel.podcasts.isEmpty {
          LiveChannelPodcastsView(
            podcasts: viewModel.podcasts,
            isLoading: viewModel.isLoadingPodcasts,
            canLoadMore: viewModel.canLoadMorePodcasts,
            onSelect: selectPodcast,
            onLoadMore: {
              Task { await viewModel.loadMorePodcasts() }
            }
          )
        }

        LiveChannelControlsView(viewModel: viewModel)
        stateContent
      }
      .padding(16)
    }
    .background(DemoTheme.background)
    .refreshable {
      if viewModel.selectedTab == .playlists {
        await viewModel.loadPlaylists()
      } else {
        await viewModel.reloadChannel()
      }
    }
  }

  @ViewBuilder
  private var stateContent: some View {
    switch viewModel.state {
    case .idle, .loading:
      VStack(spacing: 12) {
        ProgressView()
          .controlSize(.large)
        Text("Loading channel")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 70)
    case let .failed(message):
      ContentUnavailableView {
        Label("Channel unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task {
            if viewModel.selectedTab == .playlists {
              await viewModel.loadPlaylists()
            } else {
              await viewModel.reloadChannel()
            }
          }
        }
      }
    case .empty:
      ContentUnavailableView(
        emptyTitle,
        systemImage: emptySystemImage,
        description: Text(emptyDescription)
      )
      .padding(.vertical, 50)
    case .loaded:
      loadedContent
    }
  }

  private var loadedContent: some View {
    LazyVGrid(
      columns: [
        GridItem(
          .adaptive(minimum: 300, maximum: 520),
          spacing: 20,
          alignment: .top
        ),
      ],
      alignment: .leading,
      spacing: 24
    ) {
      if viewModel.selectedTab == .playlists {
        ForEach(viewModel.playlists) { playlist in
          LiveSearchPlaylistCard(playlist: playlist) {
            selectedPlaylist = playlist
          }
        }
      } else {
        ForEach(viewModel.videos) { video in
          LiveVideoCard(
            video: video,
            deArrowStore: dependencies.deArrowStore,
            action: { selectedVideo = video }
          )
          .liveVideoQuickActions(
            video: video,
            dependencies: dependencies
          )
        }
      }
      DemoIncrementalLoadingTrigger(
        canLoadMore: viewModel.canLoadMore,
        isLoading: viewModel.isLoadingMore,
        label: "Loading more channel content",
        identifier: "live.channel.loading-more"
      ) {
        Task { await viewModel.loadMore() }
      }
    }
  }

  private func selectPodcast(_ podcast: LivePodcastItem) {
    selectedPodcast = podcast
  }

  private var emptyTitle: String {
    viewModel.selectedTab == .playlists
      ? "No playlists"
      : "No videos"
  }

  private var emptySystemImage: String {
    viewModel.selectedTab == .playlists
      ? "rectangle.stack"
      : "play.rectangle"
  }

  private var emptyDescription: String {
    if !viewModel.submittedQuery.isEmpty {
      return "No channel results for “\(viewModel.submittedQuery)”."
    }
    return "This channel has no content in the selected section."
  }
}
