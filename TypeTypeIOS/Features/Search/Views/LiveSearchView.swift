import SwiftUI

struct LiveSearchView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject var viewModel: LiveSearchViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedVideoChannelURL: String?
  @State var selectedChannel: LiveChannelResult?
  @State var selectedPlaylist: LivePlaylistResult?
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
        serviceSelection: coordinator.dependencies.serviceSelection
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
        .searchSuggestions {
          ForEach(viewModel.suggestions, id: \.self) { suggestion in
            Button {
              Task { await viewModel.submit(suggestion) }
            } label: {
              Label(suggestion, systemImage: "magnifyingglass")
            }
            .searchCompletion(suggestion)
          }
        }
        .onSubmit(of: .search) {
          Task { await viewModel.submit() }
        }
        .onChange(of: viewModel.query) {
          viewModel.queryDidChange()
        }
        .navigationDestination(item: $selectedVideo) { video in
          LiveVideoMetadataView(
            video: video,
            dependencies: coordinator.dependencies
          )
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
}
