import SwiftUI

struct ChannelView: View {
  let channelURL: String
  let coordinator: RootCoordinator
  @StateObject private var viewModel: ChannelViewModel

  init(channelURL: String, coordinator: RootCoordinator) {
    self.channelURL = channelURL
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: ChannelViewModel(url: channelURL, service: coordinator.dependencies.channelService)
    )
  }

  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.page == nil {
        ProgressView("Loading channel...")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else if let errorMessage = viewModel.errorMessage, viewModel.page == nil {
        ContentUnavailableView("Unable to load channel", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
      } else {
        List {
          if let page = viewModel.page {
            ChannelHeaderView(page: page)
              .listRowInsets(EdgeInsets())
              .listRowBackground(Color.clear)
          }

          ForEach(viewModel.videos) { video in
            NavigationLink {
              WatchView(
                videoURL: video.url,
                coordinator: coordinator,
                watchService: coordinator.dependencies.watchService,
                watchProgressService: coordinator.dependencies.watchProgressService,
                watchActionsService: coordinator.dependencies.watchActionsService
              )
            } label: {
              HomeVideoRowView(video: video)
            }
          }

          if viewModel.canLoadMore {
            if viewModel.isLoadingMore {
              ProgressView().frame(maxWidth: .infinity)
            } else {
              Button("Load more") {
                Task { await viewModel.loadMore() }
              }
              .frame(maxWidth: .infinity)
            }
          }
        }
        .listStyle(.plain)
        .refreshable {
          await viewModel.load()
        }
      }
    }
    .navigationTitle("Channel")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load()
    }
  }
}
