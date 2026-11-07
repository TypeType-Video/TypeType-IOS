import SwiftUI

struct LiveSearchView: View {
  @Environment(\.themePalette) var palette
  @ObservedObject var coordinator: RootCoordinator
  @StateObject var viewModel: LiveSearchViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedVideoChannelURL: String?
  @State var selectedChannel: LiveChannelResult?
  @State var selectedPlaylist: LivePlaylistResult?
  @FocusState private var searchIsFocused: Bool

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LiveSearchViewModel(
        searchService: coordinator.dependencies.searchService,
        historyService:
          coordinator.dependencies.searchHistoryService,
        serviceSelection: coordinator.dependencies.serviceSelection,
        imagePipeline: coordinator.dependencies.imagePipeline,
        settingsService: coordinator.dependencies.settingsService
      )
    )
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        LiveSearchBar(viewModel: viewModel, isFocused: $searchIsFocused) {
          searchIsFocused = false
          submitSearch()
        }
        if showsSuggestions {
          LiveSearchSuggestionsList(suggestions: viewModel.suggestions) { suggestion in
            searchIsFocused = false
            submitSearch(suggestion)
          } onFill: { suggestion in
            viewModel.query = suggestion
            viewModel.queryDidChange()
          }
        } else {
          content
        }
      }
      .background(LiveThemeBackground().ignoresSafeArea())
      .navigationTitle("Search")
      .toolbar(.hidden, for: .navigationBar)
      .onChange(of: viewModel.query) {
        viewModel.queryDidChange()
      }
      .onChange(of: coordinator.searchTabRetaps) {
        viewModel.query = ""
        viewModel.queryDidChange()
        searchIsFocused = true
      }
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        coordinator.dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(
        item: $selectedVideoChannelURL
      ) { channelURL in
        LiveChannelView(
          channelURL: channelURL,
          dependencies: coordinator.dependencies
        )
      }
      .navigationDestination(item: $selectedChannel) { channel in
        LiveChannelView(
          channelURL: channel.url,
          dependencies: coordinator.dependencies
        )
      }
      .navigationDestination(item: $selectedPlaylist) { playlist in
        LivePublicPlaylistView(
          playlist: playlist,
          dependencies: coordinator.dependencies
        )
      }
    }
    .task {
      await viewModel.prepare()
    }
    .accessibilityIdentifier("live.search.screen")
  }

  private var showsSuggestions: Bool {
    searchIsFocused && !viewModel.query.isEmpty && !viewModel.suggestions.isEmpty
  }
}
