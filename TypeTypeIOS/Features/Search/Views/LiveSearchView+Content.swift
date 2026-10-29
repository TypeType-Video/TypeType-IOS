import SwiftUI

extension LiveSearchView {
  @ViewBuilder
  var content: some View {
    VStack(spacing: 0) {
      // Service chips pinned at the top of search (dev feedback, plan 4.1):
      // always visible, bound to the shared service selection like the
      // home toolbar.
      if viewModel.services.count > 1 {
        serviceChipRow
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
  }

  private var serviceChipRow: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(viewModel.services) { service in
          Button {
            Task { await viewModel.selectService(service.id) }
          } label: {
            HStack(spacing: 5) {
              if service.id == viewModel.selectedServiceID {
                Image(systemName: "checkmark")
                  .font(.caption2.weight(.bold))
              }
              Text(verbatim: service.name)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(palette.surface, in: Capsule())
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier(
            "live.search.service.chip.\(service.id)"
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.search.services")
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
      .buttonStyle(.borderedProminent)
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
      .buttonStyle(.borderedProminent)
    }
    .accessibilityIdentifier("live.search.error")
  }

}
