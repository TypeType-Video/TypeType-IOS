import SwiftUI

struct DemoSubscriptionsView: View {
  enum Section: Hashable {
    case videos
    case channels
  }

  @EnvironmentObject private var session: DemoSessionStore
  @State private var section: Section = .videos
  @State private var selectedVideo: DemoVideo?
  @State private var selectedChannel: DemoSearchChannel?
  @State private var visibleVideoCount = 4
  @State private var isLoadingMore = false

  private let grid = [
    GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 18),
  ]

  init(initialSection: Section = .videos) {
    _section = State(initialValue: initialSection)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        DemoSubscriptionsHeader(selection: $section)
          .padding(.horizontal, 16)
          .padding(.top, 12)
          .padding(.bottom, 14)

        Divider()

        ScrollView {
          content
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .defaultScrollAnchor(.top)
      }
      .background(DemoTheme.background)
      .navigationTitle("Subscriptions")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(
        DemoTheme.background.opacity(0.96),
        for: .navigationBar
      )
      .navigationDestination(item: $selectedVideo) { video in
        DemoWatchView(video: video)
      }
      .navigationDestination(item: $selectedChannel) { channel in
        DemoSearchChannelDetailView(channel: channel)
      }
    }
    .accessibilityIdentifier("demo.subscriptions.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch section {
    case .videos:
      Group {
        if followedVideos.isEmpty {
          ContentUnavailableView(
            "No followed videos",
            systemImage: "bell.slash",
            description: Text("Follow a channel to rebuild this local feed.")
          ).liveThemedEmptyState()
          .frame(maxWidth: .infinity)
          .padding(.top, 70)
        } else {
          LazyVGrid(columns: grid, alignment: .leading, spacing: 26) {
            ForEach(followedVideos.prefix(visibleVideoCount)) { video in
              DemoVideoCard(video: video) { selected in
                selectedVideo = selected
              }
            }

            DemoIncrementalLoadingTrigger(
              canLoadMore: visibleVideoCount < followedVideos.count,
              isLoading: isLoadingMore,
              label: "Loading more subscriptions",
              identifier: "demo.subscriptions.loading",
              action: loadMore
            )
          }
        }
      }
      .accessibilityIdentifier("demo.subscriptions.videos")
    case .channels:
      LazyVStack(spacing: 4) {
        ForEach(followedChannels) { channel in
          DemoSubscriptionChannelRow(channel: channel) {
            selectedChannel = DemoSearchCatalog.channels.first {
              $0.id == channel.id
            }
          }
          if channel.id != DemoSubscriptionCatalog.channels.last?.id {
            Divider()
          }
        }
      }
      .accessibilityIdentifier("demo.subscriptions.channels")
    }
  }

  private var followedVideos: [DemoVideo] {
    DemoSubscriptionCatalog.videos.filter { video in
      guard let channelID = DemoSubscriptionCatalog.channelID(for: video) else {
        return true
      }
      return session.followedChannelIDs.contains(channelID)
        && !session.hiddenVideoIDs.contains(video.id)
        && !session.blockedVideoIDs.contains(video.id)
        && !session.blockedChannelNames.contains(video.channel)
        && (
          !session.isInstanceAllowListRestricted
            || session.globalAllowedChannels.contains(video.channel)
        )
    }
  }

  private var followedChannels: [DemoSubscriptionChannel] {
    DemoSubscriptionCatalog.channels.filter {
      session.followedChannelIDs.contains($0.id)
        && (
          !session.isInstanceAllowListRestricted
            || session.globalAllowedChannels.contains($0.name)
        )
    }
  }

  private func loadMore() {
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(400))
      visibleVideoCount = min(followedVideos.count, visibleVideoCount + 4)
      isLoadingMore = false
    }
  }
}
