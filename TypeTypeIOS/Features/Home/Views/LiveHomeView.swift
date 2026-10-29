import SwiftUI

struct LiveHomeView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var notificationCenter: LiveNotificationCenter
  @StateObject var viewModel: LiveHomeViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    notificationCenter = coordinator.dependencies.notificationCenter
    _viewModel = StateObject(
      wrappedValue: LiveHomeViewModel(
        service: coordinator.dependencies.homeFeedService,
        historyService: coordinator.dependencies.historyService,
        settingsService: coordinator.dependencies.settingsService,
        serviceSelection: coordinator.dependencies.serviceSelection,
        imagePipeline: coordinator.dependencies.imagePipeline
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
          accountsToolbar
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
