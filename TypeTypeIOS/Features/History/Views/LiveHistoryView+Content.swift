import SwiftUI

extension LiveHistoryView {
  @ViewBuilder
  var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView("Loading history")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView {
        Label("History unavailable", systemImage: "wifi.exclamationmark")
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

  @ViewBuilder
  private var loadedContent: some View {
    if viewModel.items.isEmpty {
      ContentUnavailableView(
        viewModel.query.isEmpty ? "No watch history" : "No results",
        systemImage: "clock.arrow.circlepath",
        description: Text(
          viewModel.query.isEmpty
            ? "Videos you watch will appear here."
            : "Try another search or date."
        )
      )
    } else {
      ScrollView {
        LiveHistoryFilterBar(
          filter: viewModel.filter,
          count: viewModel.items.count,
          onSelect: viewModel.setFilter,
          onOlder: { choosesDate = true }
        )
        LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
          ForEach(viewModel.items) { item in
            LiveHistoryCard(
              item: item,
              dependencies: coordinator.dependencies,
              onSelect: { selectedVideo = item.video },
              onChannel: {
                guard !item.channelURL.isEmpty else { return }
                selectedChannelURL = item.channelURL
              },
              onRemove: { pendingRemoval = item }
            )
          }
          DemoIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more history",
            identifier: "live.history.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
      }
      .refreshable { await viewModel.reload() }
      .background(DemoThemeBackground())
      .liveThemeRepaint()
    }
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 330, maximum: 520),
        spacing: 18,
        alignment: .top
      ),
    ]
  }

  var removalBinding: Binding<Bool> {
    Binding(
      get: { pendingRemoval != nil },
      set: { if !$0 { pendingRemoval = nil } }
    )
  }

  var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
