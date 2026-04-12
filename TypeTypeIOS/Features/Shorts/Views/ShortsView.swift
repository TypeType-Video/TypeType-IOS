import SwiftUI

struct ShortsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: ShortsViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: ShortsViewModel(service: coordinator.dependencies.shortsService)
    )
  }

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading && viewModel.items.isEmpty {
          ProgressView("Loading shorts...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.items.isEmpty {
          ContentUnavailableView("No shorts yet", systemImage: "play.tv", description: Text("Try again in a moment."))
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
              if viewModel.isLoadingMore {
                ProgressView().frame(maxWidth: .infinity)
              } else {
                Button("Load more") {
                  Task { await viewModel.loadMore(serviceID: 0) }
                }
                .frame(maxWidth: .infinity)
              }
            }
          }
          .listStyle(.plain)
          .refreshable {
            await viewModel.loadInitial(serviceID: 0)
          }
        }
      }
      .navigationTitle("Shorts")
    }
    .task {
      await viewModel.loadInitial(serviceID: 0)
    }
  }
}
