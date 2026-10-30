import SwiftUI

extension LiveSearchView {
  @ViewBuilder
  var content: some View {
    VStack(spacing: 0) {
      if showsResultFilters {
        LiveSearchFilterBar(viewModel: viewModel, showsResultFilters: true)
      }
      if viewModel.submittedQuery.isEmpty {
        discovery
      } else {
        switch viewModel.state {
        case .idle:
          discovery
        case .loading:
          searchLoading
        case .empty:
          searchEmpty
        case let .failed(message):
          searchError(message)
        case .loaded:
          searchResults
        }
      }
    }
    .background(LiveThemeBackground().ignoresSafeArea())
  }

  private var showsResultFilters: Bool {
    guard !viewModel.submittedQuery.isEmpty else { return false }
    switch viewModel.state {
    case .loaded, .empty: return true
    default: return false
    }
  }

  private var discovery: some View {
    LiveSearchHistoryView(viewModel: viewModel)
  }

  private var searchLoading: some View {
    TypeTypeSkeletonList(layout: .cards)
      .accessibilityIdentifier("live.search.loading")
  }

  private var searchEmpty: some View {
    ContentUnavailableView {
      Label("No results", systemImage: "magnifyingglass")
    } description: {
      Text(
        "Try fewer words, another service, or a broader filter."
      )
    } actions: {
      Button("Clear search") {
        viewModel.query = ""
        viewModel.queryDidChange()
      }
      .liveProminentButton()
    }
    .accessibilityIdentifier("live.search.empty")
  }

  private func searchError(_ message: String) -> some View {
    ContentUnavailableView {
      Label("Search unavailable", systemImage: "wifi.exclamationmark")
    } description: {
      Text(message)
    } actions: {
      Button("Try again") {
        Task { await viewModel.submit(viewModel.submittedQuery) }
      }
      .liveProminentButton()
    }
    .accessibilityIdentifier("live.search.error")
  }

}
