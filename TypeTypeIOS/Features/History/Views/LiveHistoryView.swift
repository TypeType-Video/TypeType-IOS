import SwiftUI

struct LiveHistoryView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject var viewModel: LiveHistoryViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?
  @State var pendingRemoval: LiveHistoryItem?
  @State var confirmsClear = false
  @State var choosesDate = false

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LiveHistoryViewModel(
        service: coordinator.dependencies.historyService
      )
    )
  }

  var body: some View {
    NavigationStack {
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
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Clear", role: .destructive) {
              confirmsClear = true
            }
            .disabled(viewModel.items.isEmpty)
          }
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
    .task { await viewModel.prepare() }
    .sheet(isPresented: $choosesDate) {
      LiveHistoryDateSheet { date in
        viewModel.setFilter(.date(date))
      }
    }
    .confirmationDialog(
      "Clear watch history?",
      isPresented: $confirmsClear,
      titleVisibility: .visible
    ) {
      Button("Clear all", role: .destructive) {
        Task { await viewModel.clear() }
      }
    } message: {
      Text("This removes every video from your watch history.")
    }
    .confirmationDialog(
      "Remove from history?",
      isPresented: removalBinding,
      titleVisibility: .visible
    ) {
      Button("Remove", role: .destructive) {
        guard let item = pendingRemoval else { return }
        Task { await viewModel.remove(item) }
        pendingRemoval = nil
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
