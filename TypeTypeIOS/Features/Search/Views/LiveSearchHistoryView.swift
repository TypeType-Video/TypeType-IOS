import SwiftUI

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
    .background(LiveThemeBackground().ignoresSafeArea())
    .refreshable {
      await viewModel.loadHistory()
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
        .popover(
          isPresented: $confirmsClear,
          attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
          arrowEdge: .top
        ) {
          LiveConfirmCard(
            title: "Clear search history?",
            message: "This removes all saved searches from your account.",
            confirmTitle: "Clear all"
          ) {
            Task { await viewModel.clearHistory() }
          }
        }
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
      LiveIncrementalLoadingTrigger(
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
