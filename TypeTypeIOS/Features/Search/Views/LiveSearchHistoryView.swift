import SwiftUI

struct LiveSearchHistoryView: View {
  @ObservedObject var viewModel: LiveSearchViewModel
  @State private var confirmsClear = false

  var body: some View {
    Group {
      if viewModel.history.isEmpty {
        ContentUnavailableView(
          "Search TypeType",
          systemImage: "magnifyingglass",
          description: Text("Find videos, channels, and playlists on any service.")
        )
        .liveThemedEmptyState()
      } else {
        List {
          Section {
            ForEach(viewModel.history) { item in
              row(item.term)
            }
            LiveIncrementalLoadingTrigger(
              canLoadMore: viewModel.canLoadMoreHistory,
              isLoading: false,
              label: "Loading more search history",
              identifier: "live.search.history-more"
            ) {
              Task { await viewModel.loadMoreHistory() }
            }
            .listRowSeparator(.hidden)
          } header: {
            header
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
      }
    }
    .background(LiveThemeBackground().ignoresSafeArea())
    .scrollDismissesKeyboard(.immediately)
    .refreshable { await viewModel.loadHistory() }
    .confirmationDialog("Clear search history?", isPresented: $confirmsClear, titleVisibility: .visible) {
      Button("Clear all", role: .destructive) {
        Task { await viewModel.clearHistory() }
      }
    } message: {
      Text("This removes all saved searches from your account.")
    }
    .accessibilityIdentifier("live.search.history")
  }

  private var header: some View {
    HStack {
      Text("Recent searches").liveSectionHeader()
      Button("Clear") { confirmsClear = true }
        .font(.subheadline)
        .accessibilityHint(Text("Removes all saved searches"))
    }
    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
  }

  private func row(_ term: String) -> some View {
    HStack(spacing: 14) {
      Button {
        Task { await viewModel.submit(term) }
      } label: {
        HStack(spacing: 14) {
          Image(systemName: "clock.arrow.circlepath")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
          Text(term)
            .foregroundStyle(.primary)
            .lineLimit(1)
          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint(Text("Searches again"))
      Button {
        viewModel.query = term
        viewModel.queryDidChange()
      } label: {
        Image(systemName: "arrow.up.left")
          .foregroundStyle(.secondary)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Text("Edit \(term)"))
    }
    .listRowBackground(Color.clear)
  }
}
