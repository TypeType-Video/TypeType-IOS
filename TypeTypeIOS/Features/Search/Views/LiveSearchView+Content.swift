import SwiftUI

extension LiveSearchView {
  @ViewBuilder
  var content: some View {
    VStack(spacing: 0) {
      // Service chips pinned at the top of search (dev feedback, plan 4.1):
      // always visible, bound to the shared service selection like the
      // home toolbar.
      if viewModel.services.count > 1 {
        serviceChipRow
      }
      if viewModel.submittedQuery.isEmpty {
        discovery
      } else {
        switch viewModel.state {
        case .idle:
          discovery
        case .loading:
          searchLoading
        case .empty:
          searchEmpty
        case let .failed(message):
          searchError(message)
        case .loaded:
          searchResults
        }
      }
    }
  }

  private var serviceChipRow: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(viewModel.services) { service in
          Button {
            Task { await viewModel.selectService(service.id) }
          } label: {
            HStack(spacing: 5) {
              if service.id == viewModel.selectedServiceID {
                Image(systemName: "checkmark")
                  .font(.caption2.weight(.bold))
              }
              Text(verbatim: service.name)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(DemoTheme.surface, in: Capsule())
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier(
            "live.search.service.chip.\(service.id)"
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.search.services")
  }

  private var discovery: some View {
    LiveSearchHistoryView(viewModel: viewModel)
  }

  private var searchLoading: some View {
    TypeTypeSkeletonList(layout: .cards)
.accessibilityIdentifier("live.search.loading")
  }

  private var searchEmpty: some View {
    ContentUnavailableView {
      Label("No results", systemImage: "magnifyingglass")
    } description: {
      Text(
        "Try fewer words, another service, or a broader filter."
      )
    } actions: {
      Button("Clear search") {
        viewModel.query = ""
        viewModel.queryDidChange()
      }
      .buttonStyle(.borderedProminent)
    }
    .accessibilityIdentifier("live.search.empty")
  }

  private func searchError(_ message: String) -> some View {
    ContentUnavailableView {
      Label("Search unavailable", systemImage: "wifi.exclamationmark")
    } description: {
      Text(message)
    } actions: {
      Button("Try again") {
        Task { await viewModel.submit(viewModel.submittedQuery) }
      }
      .buttonStyle(.borderedProminent)
    }
    .accessibilityIdentifier("live.search.error")
  }

  private var searchResults: some View {
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
      .liveThemeRepaint()
  }

  @ViewBuilder
  private func resultView(_ result: LiveSearchResult) -> some View {
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
