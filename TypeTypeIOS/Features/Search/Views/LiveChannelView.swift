import SwiftUI

struct LiveChannelView: View {
  let dependencies: AppDependencies
  @StateObject var viewModel: LiveChannelViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedPlaylist: LivePlaylistResult?
  @State var selectedPodcast: LivePodcastItem?

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
      // The in-page search bar is gone (dev feedback, plan task 5):
      // searching belongs to the search tab.
      .navigationTitle(viewModel.channel?.name ?? "Channel")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await viewModel.loadIfNeeded()
      }
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        // Videos open in the canonical PiP-aware player cover;
        // the navigation push slid a second player page in.
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
