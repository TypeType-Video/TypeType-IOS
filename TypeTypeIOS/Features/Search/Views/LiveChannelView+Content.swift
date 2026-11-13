import SwiftUI

extension LiveChannelView {
  var content: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        if let channel = viewModel.channel, !channel.bannerURL.isEmpty {
          LiveChannelBanner(url: channel.banner)
            .padding(.horizontal, -16)
            .padding(.top, -16)
            .padding(.bottom, -28)
        }
        if let channel = viewModel.channel {
          LiveChannelHeaderView(
            channel: channel,
            isSubscribed: viewModel.isSubscribed,
            isChangingSubscription:
              viewModel.isChangingSubscription,
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
    .background(LiveThemeBackground().ignoresSafeArea())
    .refreshable {
      if viewModel.selectedTab.listsPlaylists {
        await viewModel.loadPlaylists()
      } else {
        await viewModel.reloadChannel()
      }
    }
  }

  @ViewBuilder
  private var stateContent: some View {
    if viewModel.selectedTab == .posts {
      LiveChannelPostsView(channelURL: viewModel.channelURL, service: viewModel.channelService, onOpenURL: routeLink)
    } else {
      channelStateContent
    }
  }

  @ViewBuilder
  private var channelStateContent: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .cards, count: 3, scrolls: false)
    case let .failed(message):
      ContentUnavailableView {
        Label("Channel unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task {
            if viewModel.selectedTab.listsPlaylists {
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
      ).liveThemedEmptyState()
      .padding(.vertical, 50)
    case .loaded:
      if viewModel.selectedTab == .about {
        aboutContent
      } else {
        loadedContent
      }
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
      if viewModel.selectedTab.listsPlaylists {
        ForEach(viewModel.playlists) { playlist in
          LiveSearchPlaylistCard(playlist: playlist) {
            selectedPlaylist = playlist
          }
        }
      } else {
        LiveHiddenVideosReader(dependencies.hiddenVideos) { hidden in
          ForEach(hidden.visible(viewModel.videos)) { video in
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
      }
      LiveIncrementalLoadingTrigger(
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

}
