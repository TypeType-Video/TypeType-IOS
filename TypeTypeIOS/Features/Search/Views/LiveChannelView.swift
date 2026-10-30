import SwiftUI

struct LiveChannelView: View {
  let dependencies: AppDependencies
  @StateObject var viewModel: LiveChannelViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedPlaylist: LivePlaylistResult?
  @State var selectedPodcast: LivePodcastItem?
  @State var selectedChannelURL: String?
  @State var pendingExternalURL: URL?

  init(
    channelURL: String,
    dependencies: AppDependencies
  ) {
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LiveChannelViewModel(
        channelURL: channelURL,
        channelService: dependencies.channelService,
        subscriptionsService: dependencies.subscriptionsService,
        pushNotificationsService:
          dependencies.pushNotificationsService,
        pushNotificationsEnabled:
          dependencies.pushNotificationsEnabled
      )
    )
  }

  var body: some View {
    content
      .navigationTitle(viewModel.channel?.name ?? "Channel")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await viewModel.loadIfNeeded()
      }
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(item: $selectedPlaylist) { playlist in
        LivePublicPlaylistView(
          playlist: playlist,
          dependencies: dependencies
        )
      }
      .navigationDestination(item: $selectedPodcast) { podcast in
        LivePodcastEpisodesView(
          podcast: podcast,
          dependencies: dependencies
        )
      }
      .navigationDestination(item: $selectedChannelURL) { channelURL in
        LiveChannelView(channelURL: channelURL, dependencies: dependencies)
      }
      .externalLinkAlert(pendingURL: $pendingExternalURL)
      .alert(
        "Subscription unavailable",
        isPresented: subscriptionErrorBinding
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(viewModel.subscriptionError ?? "")
      }
      .accessibilityIdentifier("live.channel.screen")
  }

  func routeLink(_ url: URL) {
    switch LiveMediaLinkResolver.destination(for: url, serverURL: dependencies.serverStore.selectedServer()?.baseURL) {
    case let .video(video): selectedVideo = video
    case let .channel(channelURL): selectedChannelURL = channelURL
    case let .playlist(playlist): selectedPlaylist = playlist
    case nil: pendingExternalURL = url
    }
  }

  private var subscriptionErrorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.subscriptionError != nil },
      set: { presented in
        if !presented {
          viewModel.subscriptionError = nil
        }
      }
    )
  }
}
