import SwiftUI

struct LivePublicPlaylistView: View {
  let dependencies: AppDependencies
  @StateObject var viewModel: LivePublicPlaylistViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?

  init(
    playlist: LivePlaylistResult,
    dependencies: AppDependencies
  ) {
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LivePublicPlaylistViewModel(
        playlist: playlist,
        service: dependencies.playlistsService
      )
    )
  }

  var body: some View {
    content
      .navigationTitle("Playlist")
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        // Videos open in the canonical PiP-aware player cover;
        // the navigation push slid a second player page in.
        dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(item: $selectedChannelURL) { channelURL in
        LiveChannelView(
          channelURL: channelURL,
          dependencies: dependencies
        )
      }
      .task { await viewModel.prepare() }
      .alert("Playlist", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.public-playlist.screen")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading playlist")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("Playlist unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      loadedContent
    }
  }

  private var loadedContent: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        LivePublicPlaylistHeader(
          playlist: viewModel.playlist,
          isSaved: viewModel.savedID != nil,
          isPreparingPlayback: viewModel.isPreparingPlayback,
          onPlayAll: {
            Task { await startPlayback(shuffle: false) }
          },
          onShuffle: {
            Task { await startPlayback(shuffle: true) }
          },
          onToggleSaved: {
            Task { await viewModel.toggleSaved() }
          }
        )
        if viewModel.videos.isEmpty {
          ContentUnavailableView(
            "No videos",
            systemImage: "rectangle.stack"
          )
          .frame(maxWidth: .infinity)
          .padding(.top, 50)
        } else {
          LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
            ForEach(viewModel.videos) { video in
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
              label: "Loading more playlist videos",
              identifier: "live.public-playlist.loading-more"
            ) {
              Task { await viewModel.loadMore() }
            }
          }
        }
      }
      .padding(16)
    }
    .refreshable { await viewModel.reload() }
    .background(DemoThemeBackground())
      .liveThemeRepaint()
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 330, maximum: 520),
        spacing: 22,
        alignment: .top
      ),
    ]
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }

  private func startPlayback(shuffle: Bool) async {
    guard let videos = await viewModel.videosForPlayback() else {
      return
    }
    selectedVideo = dependencies.playbackCoordinator.startQueue(
      title: viewModel.playlist.title,
      videos: videos,
      shuffle: shuffle
    )
  }
}
