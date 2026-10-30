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
  @Environment(\.dismissSearch) private var dismissSearch
  private let onClose: () -> Void

  init(
    coordinator: RootCoordinator,
    onClose: @escaping () -> Void
  ) {
    self.coordinator = coordinator
    self.onClose = onClose
    _viewModel = StateObject(
      wrappedValue: LiveSearchViewModel(
        searchService: coordinator.dependencies.searchService,
        historyService:
          coordinator.dependencies.searchHistoryService,
        serviceSelection: coordinator.dependencies.serviceSelection,
        imagePipeline: coordinator.dependencies.imagePipeline
      )
    )
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Close", systemImage: "xmark") {
              onClose()
            }
          }
        }
        .searchable(
          text: $viewModel.query,
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: "Search videos, channels..."
        )
        .trackingSearchFocus($searchIsFocused)
        .searchSuggestions {
          ForEach(viewModel.suggestions, id: \.self) { suggestion in
            Button {
              closeSearchInput()
              Task { await viewModel.submit(suggestion) }
            } label: {
              Label(suggestion, systemImage: "magnifyingglass")
            }
            .searchCompletion(suggestion)
          }
        }
        .onSubmit(of: .search) {
          closeSearchInput()
          Task { await viewModel.submit() }
        }
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

  private func closeSearchInput() {
    searchIsFocused = false
    dismissSearch()
  }
}

private extension View {
  @ViewBuilder
  func trackingSearchFocus(
    _ focus: FocusState<Bool>.Binding
  ) -> some View {
    if #available(iOS 18.0, *) {
      searchFocused(focus)
    } else {
      self
    }
  }
}
