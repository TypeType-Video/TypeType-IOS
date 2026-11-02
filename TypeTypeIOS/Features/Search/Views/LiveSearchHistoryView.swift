import SwiftUI

struct LiveSearchHistoryView: View {
  @ObservedObject var viewModel: LiveSearchViewModel
  let onSubmit: (String) -> Void
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
          LiveSection {
            ForEach(Array(viewModel.history.enumerated()), id: \.element.id) { index, item in
              row(item.term)
                .swipeActions {
                  Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteHistory(item) }
                  }
                }
                .onAppear {
                  guard viewModel.canLoadMoreHistory, index >= viewModel.history.count - 3 else { return }
                  Task { await viewModel.loadMoreHistory() }
                }
            }
          } header: {
            header
          }
        }
        .liveGroupedList()
        .contentMargins(.top, 0, for: .scrollContent)
      }
    }
    .scrollDismissesKeyboard(.immediately)
    .refreshable { await viewModel.loadHistory() }
    .accessibilityIdentifier("live.search.history")
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      Text("Recent searches").liveSectionHeader()
      Button("Clear") { confirmsClear = true }
        .font(.subheadline.weight(.semibold))
        .accessibilityHint(Text("Removes all saved searches"))
        .alert("Clear search history?", isPresented: $confirmsClear) {
          Button("Cancel", role: .cancel) {}
          Button("Clear all", role: .destructive) {
            Task { await viewModel.clearHistory() }
          }
        } message: {
          Text("This removes all saved searches from your account.")
        }
    }
  }

  private func row(_ term: String) -> some View {
    HStack(spacing: 12) {
      Button {
        onSubmit(term)
      } label: {
        Label {
          Text(term)
            .foregroundStyle(.primary)
            .lineLimit(1)
        } icon: {
          Image(systemName: "clock.arrow.circlepath")
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint(Text("Searches again"))
      Button {
        viewModel.query = term
        viewModel.queryDidChange()
      } label: {
        Image(systemName: "arrow.up.left")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Text("Edit \(term)"))
    }
  }
}
