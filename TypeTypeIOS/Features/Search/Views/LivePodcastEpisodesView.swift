import SwiftUI

struct LivePodcastEpisodesView: View {
  let dependencies: AppDependencies
  @StateObject private var viewModel: LivePodcastEpisodesViewModel
  @State private var selectedVideo: LiveVideoItem?
  @State private var selectedChannelURL: String?

  init(
    podcast: LivePodcastItem,
    dependencies: AppDependencies
  ) {
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LivePodcastEpisodesViewModel(
        podcast: podcast,
        service: dependencies.channelService
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Podcast")
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(item: $selectedChannelURL) { channelURL in
        LiveChannelView(
          channelURL: channelURL,
          dependencies: dependencies
        )
      }
      .task { await viewModel.prepare() }
      .accessibilityIdentifier("live.podcast-episodes.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .rows, count: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Podcast unavailable", systemImage: "mic.slash")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .empty:
      ContentUnavailableView(
        "No episodes",
        systemImage: "mic",
        description: Text("This podcast has no published episodes.")
      ).liveThemedEmptyState()
    case .loaded:
      loadedContent
    }
  }

  private var loadedContent: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        header
        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
          ForEach(viewModel.episodes) { video in
            LiveVideoCard(
              video: video,
              deArrowStore: dependencies.deArrowStore,
              onChannel: {
                guard !video.uploaderURL.isEmpty else { return }
                selectedChannelURL = video.uploaderURL
              },
              action: { selectedVideo = video }
            )
            .liveVideoQuickActions(
              video: video,
              dependencies: dependencies,
              onOpenChannel: {
                guard !video.uploaderURL.isEmpty else { return }
                selectedChannelURL = video.uploaderURL
              }
            )
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more podcast episodes",
            identifier: "live.podcast-episodes.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        }
      }
      .padding(16)
    }
    .refreshable { await viewModel.reload() }
    .background(DemoThemeBackground().ignoresSafeArea())
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 16) {
      LiveRemoteImage(url: URL(string: viewModel.podcast.thumbnailURL))
        .frame(width: 84, height: 84)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
      VStack(alignment: .leading, spacing: 5) {
        Label("Podcast", systemImage: "mic.fill")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(viewModel.podcast.title)
          .font(.title3.weight(.bold))
          .lineLimit(2)
        Text(viewModel.podcast.uploaderName)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 300, maximum: 520),
        spacing: 20,
        alignment: .top
      ),
    ]
  }
}
