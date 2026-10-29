import SwiftUI

extension LiveSearchView {
  var searchResults: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 18) {
        LiveSearchFilterBar(viewModel: viewModel)
        if let suggestion = viewModel.searchSuggestion,
          !suggestion.isEmpty {
          LiveSearchSuggestionView(
            query: viewModel.submittedQuery,
            suggestion: suggestion,
            isCorrected: viewModel.isCorrectedSearch
          ) {
            Task { await viewModel.submit(suggestion) }
          }
        }
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
          ForEach(viewModel.results) { result in
            resultView(result)
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more search results",
            identifier: "live.search.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        }
      }
      .padding(16)
    }
    .scrollDismissesKeyboard(.immediately)
    .background(DemoThemeBackground().ignoresSafeArea())
  }

  @ViewBuilder
  func resultView(_ result: LiveSearchResult) -> some View {
    switch result {
    case let .channel(channel):
      LiveSearchChannelCard(channel: channel) {
        selectedChannel = channel
      }
    case let .playlist(playlist):
      LiveSearchPlaylistCard(playlist: playlist) {
        selectedPlaylist = playlist
      }
    case let .video(video):
      LiveVideoCard(
        video: video,
        deArrowStore: coordinator.dependencies.deArrowStore,
        onChannel: {
          guard !video.uploaderURL.isEmpty else { return }
          selectedVideoChannelURL = video.uploaderURL
        },
        action: { selectedVideo = video }
      )
      .liveVideoQuickActions(
        video: video,
        dependencies: coordinator.dependencies,
        onOpenChannel: {
          guard !video.uploaderURL.isEmpty else { return }
          selectedVideoChannelURL = video.uploaderURL
        }
      )
    }
  }
}
