import SwiftUI

struct SearchView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: SearchViewModel
  @State private var serviceID: Int = DefaultServiceStore.get()

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: SearchViewModel(
        searchService: coordinator.dependencies.searchService,
        blockedService: coordinator.dependencies.blockedService
      )
    )
  }

  private var trimmedQuery: String {
    viewModel.inputQuery.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func loadDefaultServiceID() async {
    do {
      let settings = try await coordinator.dependencies.userSettingsService.get()
      serviceID = settings.defaultService
      DefaultServiceStore.set(settings.defaultService)
    } catch {
      serviceID = DefaultServiceStore.get()
    }
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
          viewModel.applySuggestion(suggestion)
          Task { await viewModel.performSearch(serviceID: serviceID) }
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
            TextField("Search videos", text: $viewModel.inputQuery)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .submitLabel(.search)
              .onChange(of: viewModel.inputQuery) { _, _ in
                viewModel.refreshSearchInput(serviceID: serviceID)
              }
              .onSubmit {
                Task { await viewModel.performSearch(serviceID: serviceID) }
              }
            if !trimmedQuery.isEmpty {
              Button {
                viewModel.inputQuery = ""
                viewModel.query = ""
                viewModel.clearSuggestions()
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
            Task { await viewModel.performSearch(serviceID: serviceID) }
          }
          .buttonStyle(.borderedProminent)
          .disabled(trimmedQuery.isEmpty)
        }
        .padding(.horizontal)

        if !viewModel.suggestions.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
              ForEach(viewModel.suggestions, id: \.self) { value in
                Button {
                  viewModel.applySuggestion(value)
                  Task { await viewModel.performSearch(serviceID: serviceID) }
                } label: {
                  Text(value)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TypeTypeColor.card)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal)
          }
        }

        if trimmedQuery.isEmpty {
          if viewModel.isLoadingHistory {
            ProgressView("Loading recent searches...")
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
          } else if !viewModel.history.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Recent searches")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") {
                  Task { await viewModel.clearHistory() }
                }
                .font(.caption)
              }
              .padding(.horizontal)

              ForEach(viewModel.history) { item in
                Button {
                  viewModel.applySuggestion(item.term)
                  Task { await viewModel.performSearch(serviceID: serviceID) }
                } label: {
                  HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                      .foregroundStyle(.secondary)
                    Text(item.term)
                      .lineLimit(1)
                    Spacer()
                  }
                  .padding(.horizontal)
                }
                .buttonStyle(.plain)
              }
              Divider()
            }
          }
        }

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
                    Task { await viewModel.loadMore(serviceID: serviceID) }
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
    .task(id: coordinator.selectedServer?.id) {
      await loadDefaultServiceID()
      await viewModel.loadHistory()
    }
  }
}
