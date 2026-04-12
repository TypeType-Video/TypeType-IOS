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

  private var trimmedQuery: String {
    viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  @ViewBuilder
  private var statusSection: some View {
    if let suggestion = viewModel.suggestion, !suggestion.isEmpty {
      let label = viewModel.isCorrected ? "Showing results for" : "Did you mean"
      HStack {
        Text(label)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(suggestion)
          .font(.caption.weight(.semibold))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(TypeTypeColor.card)
          .clipShape(Capsule())
        Spacer()
        Button("Use") {
          viewModel.query = suggestion
          Task { await viewModel.performSearch(serviceID: 0) }
        }
        .font(.caption)
      }
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
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundStyle(.secondary)
            TextField("Search videos", text: $viewModel.query)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .submitLabel(.search)
              .onSubmit {
                Task { await viewModel.performSearch(serviceID: 0) }
              }
            if !trimmedQuery.isEmpty {
              Button {
                viewModel.query = ""
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundStyle(.secondary)
              }
            }
          }
          .padding(.horizontal, 12)
          .frame(height: 38)
          .background(TypeTypeColor.card)
          .clipShape(RoundedRectangle(cornerRadius: 10))

          Button(viewModel.isLoading ? "..." : "Search") {
            Task { await viewModel.performSearch(serviceID: 0) }
          }
          .buttonStyle(.borderedProminent)
          .disabled(trimmedQuery.isEmpty)
        }
        .padding(.horizontal)

        statusSection

        if viewModel.isLoading && viewModel.items.isEmpty {
          ProgressView("Searching...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.items.isEmpty {
          ContentUnavailableView(
            trimmedQuery.isEmpty ? "Search TypeType" : "No results for \"\(trimmedQuery)\"",
            systemImage: "magnifyingglass",
            description: trimmedQuery.isEmpty ? nil : Text("Try another keyword or remove filters.")
          )
            .frame(maxHeight: .infinity)
        } else {
          List {
            ForEach(viewModel.items) { item in
              NavigationLink {
                WatchView(
                  videoURL: item.url,
                  coordinator: coordinator,
                  watchService: coordinator.dependencies.watchService,
                  watchProgressService: coordinator.dependencies.watchProgressService,
                  watchActionsService: coordinator.dependencies.watchActionsService
                )
              } label: {
                HomeVideoRowView(video: item)
              }
            }
            if viewModel.canLoadMore {
              HStack {
                if viewModel.isLoadingMore {
                  ProgressView()
                  Text("Loading more...")
                } else {
                  Button("Load more") {
                    Task { await viewModel.loadMore(serviceID: 0) }
                  }
                  .buttonStyle(.borderless)
                }
              }
              .frame(maxWidth: .infinity, alignment: .center)
            }
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Search")
    }
  }
}
