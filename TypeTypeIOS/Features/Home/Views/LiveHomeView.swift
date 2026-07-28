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
        .navigationDestination(item: $selectedVideo) { video in
          LiveVideoMetadataView(
            video: video,
            dependencies: coordinator.dependencies
          )
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
