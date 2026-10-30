import SwiftUI

struct LiveHistoryView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var viewModel: LiveHistoryViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?
  @State var pendingRemoval: LiveHistoryItem?
  @State var choosesDate = false

  init(
    coordinator: RootCoordinator,
    viewModel: LiveHistoryViewModel,
    isActive: Bool = true
  ) {
    self.coordinator = coordinator
    self.viewModel = viewModel
    self.isActive = isActive
  }

  var isActive = true

  var body: some View {
    content
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .searchableWhenActive(
        isActive,
        text: $viewModel.query,
        prompt: "Search history"
      )
      .onChange(of: viewModel.query) {
        viewModel.queryDidChange()
      }
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
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

private extension View {
  // .searchable attaches to the library's shared bar: attach it only while this section is active.
  @ViewBuilder
  func searchableWhenActive(
    _ active: Bool,
    text: Binding<String>,
    prompt: String
  ) -> some View {
    if active {
      searchable(text: text, prompt: prompt)
    } else {
      self
    }
  }
}
