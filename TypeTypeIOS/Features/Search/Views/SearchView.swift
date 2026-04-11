import SwiftUI

struct SearchView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: SearchViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: SearchViewModel(searchService: coordinator.dependencies.searchService)
    )
  }

  @ViewBuilder
  private var statusSection: some View {
    if let suggestion = viewModel.suggestion, !suggestion.isEmpty {
      let label = viewModel.isCorrected ? "Showing results for" : "Did you mean"
      Text("\(label) \(suggestion)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
        .padding(.horizontal)
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 10) {
        HStack(spacing: 8) {
          TextField("Search videos", text: $viewModel.query)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
              Task { await viewModel.performSearch(serviceID: 0) }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.secondary.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 8))

          Button(viewModel.isLoading ? "..." : "Go") {
            Task { await viewModel.performSearch(serviceID: 0) }
          }
          .buttonStyle(.borderedProminent)
          .disabled(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)

        statusSection

        if viewModel.isLoading && viewModel.items.isEmpty {
          ProgressView("Searching...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.items.isEmpty {
          ContentUnavailableView("Search TypeType", systemImage: "magnifyingglass")
            .frame(maxHeight: .infinity)
        } else {
          List {
            ForEach(viewModel.items) { item in
              NavigationLink {
                WatchView(videoURL: item.url, watchService: coordinator.dependencies.watchService)
              } label: {
                HomeVideoRowView(video: item)
              }
            }
            if viewModel.canLoadMore {
              Button(viewModel.isLoadingMore ? "Loading..." : "Load more") {
                Task { await viewModel.loadMore(serviceID: 0) }
              }
              .disabled(viewModel.isLoadingMore)
            }
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Search")
    }
  }
}
