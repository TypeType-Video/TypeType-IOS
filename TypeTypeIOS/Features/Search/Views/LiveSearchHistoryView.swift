import SwiftUI

/// Discovery state of the search screen: recent searches only. Search is
/// search — the trending shelf was removed (dev feedback, plan task 4.1).
struct LiveSearchHistoryView: View {
  @ObservedObject var viewModel: LiveSearchViewModel
  @State private var confirmsClear = false

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        if viewModel.history.isEmpty {
          ContentUnavailableView(
            "Search TypeType",
            systemImage: "magnifyingglass",
            description: Text(
              "Find videos, channels, and playlists on any service."
            )
          )
          .liveThemedEmptyState()
        } else {
          historySection
        }
      }
      .padding(16)
    }
    .background(DemoThemeBackground().ignoresSafeArea())
      .liveThemeRepaint()
    .refreshable {
      await viewModel.loadHistory()
    }
    .confirmationDialog(
      "Clear search history?",
      isPresented: $confirmsClear,
      titleVisibility: .visible
    ) {
      Button("Clear all", role: .destructive) {
        Task { await viewModel.clearHistory() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This removes all saved searches from your account.")
    }
    .accessibilityIdentifier("live.search.history")
  }

  private var historySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Recent searches")
          .font(.headline)
        Spacer()
        Button("Clear") {
          confirmsClear = true
        }
        .font(.subheadline)
      }
      ForEach(viewModel.history) { item in
        Button {
          Task { await viewModel.submit(item.term) }
        } label: {
          Label(item.term, systemImage: "clock.arrow.circlepath")
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.primary)
      }
      DemoIncrementalLoadingTrigger(
        canLoadMore: viewModel.canLoadMoreHistory,
        isLoading: false,
        label: "Loading more search history",
        identifier: "live.search.history-more"
      ) {
        Task { await viewModel.loadMoreHistory() }
      }
    }
  }
}
