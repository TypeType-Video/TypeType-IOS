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
          TabView(selection: $viewModel.activeIndex) {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { pair in
              let index = pair.offset
              let item = pair.element
              VStack(spacing: 8) {
                HomeVideoRowView(video: item)
                NavigationLink {
                  WatchView(
                    videoURL: item.url,
                    coordinator: coordinator,
                    watchService: coordinator.dependencies.watchService,
                    watchProgressService: coordinator.dependencies.watchProgressService,
                    watchActionsService: coordinator.dependencies.watchActionsService
                  )
                } label: {
                  Label("Open short", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)

                if viewModel.canLoadMore,
                  index >= max(0, viewModel.items.count - 3),
                  !viewModel.isLoadingMore {
                  Button("Load more") {
                    Task { await viewModel.loadMore(serviceID: 0) }
                  }
                  .buttonStyle(.bordered)
                }
              }
              .padding()
              .tag(index)
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .always))
          .onChange(of: viewModel.activeIndex) { _, newIndex in
            viewModel.prefetchIfNeeded(activeIndex: newIndex, serviceID: 0)
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
