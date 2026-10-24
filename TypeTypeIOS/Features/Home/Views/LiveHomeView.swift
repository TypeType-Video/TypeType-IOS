import SwiftUI

struct LiveHomeView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject var viewModel: LiveHomeViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?
  let onPresentSearch: () -> Void

  init(
    coordinator: RootCoordinator,
    onPresentSearch: @escaping () -> Void
  ) {
    self.coordinator = coordinator
    self.onPresentSearch = onPresentSearch
    _viewModel = StateObject(
      wrappedValue: LiveHomeViewModel(
        service: coordinator.dependencies.homeFeedService,
        historyService: coordinator.dependencies.historyService,
        settingsService: coordinator.dependencies.settingsService,
        serviceSelection: coordinator.dependencies.serviceSelection
      )
    )
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          brandToolbar
          serviceToolbar
          searchToolbar
        }
        .onChange(of: selectedVideo) { _, video in
          guard let video else { return }
          selectedVideo = nil
          // Videos open in the canonical PiP-aware player cover;
          // the navigation push slid a second player page in.
          coordinator.dependencies.playbackCoordinator.open(video)
        }
        .navigationDestination(item: $selectedChannelURL) { channelURL in
          LiveChannelView(
            channelURL: channelURL,
            dependencies: coordinator.dependencies
          )
        }
    }
    .task {
      await viewModel.loadIfNeeded()
    }
    .accessibilityIdentifier("live.home.screen")
  }
}
