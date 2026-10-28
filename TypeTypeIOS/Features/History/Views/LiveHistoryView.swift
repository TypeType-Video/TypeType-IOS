import SwiftUI

struct LiveHistoryView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var viewModel: LiveHistoryViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?
  @State var pendingRemoval: LiveHistoryItem?
  @State var choosesDate = false

  init(coordinator: RootCoordinator, viewModel: LiveHistoryViewModel) {
    self.coordinator = coordinator
    self.viewModel = viewModel
  }

  // No own NavigationStack: as a library section the pager hosts this view
  // inside the library's stack, whose bar collects the title, search field
  // and the Clear button. A nested stack drew its own covered bar.
  var body: some View {
    content
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(
        text: $viewModel.query,
        prompt: "Search history"
      )
      .onChange(of: viewModel.query) {
        viewModel.queryDidChange()
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
    .task { await viewModel.prepare() }
    .sheet(isPresented: $choosesDate) {
      LiveHistoryDateSheet { date in
        viewModel.setFilter(.date(date))
      }
    }
    .alert(
      "History",
      isPresented: errorBinding
    ) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.history.screen")
  }
}
