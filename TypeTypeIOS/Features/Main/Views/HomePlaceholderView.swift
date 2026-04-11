import SwiftUI

struct HomePlaceholderView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: HomeFeedViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: HomeFeedViewModel(service: coordinator.dependencies.homeFeedService)
    )
  }

  @ViewBuilder
  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let server = coordinator.selectedServer {
        Text(server.name)
          .font(.headline)
        Text(server.baseURLString)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if let session = coordinator.currentSession {
        Text("Signed in as \(session.userEmail)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading && viewModel.videos.isEmpty {
      ProgressView("Loading feed...")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    } else if let errorMessage = viewModel.errorMessage, viewModel.videos.isEmpty {
      ContentUnavailableView(
        "Unable to load videos",
        systemImage: "exclamationmark.triangle",
        description: Text(errorMessage)
      )
    } else {
      List(viewModel.videos) { video in
        NavigationLink {
          WatchView(videoURL: video.url, watchService: coordinator.dependencies.watchService)
        } label: {
          HomeVideoRowView(video: video)
        }
      }
      .listStyle(.plain)
      .refreshable {
        await viewModel.reload(serviceID: 0)
      }
    }
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 10) {
        header
        content
      }
      .navigationTitle("Home")
    }
    .task(id: coordinator.selectedServer?.id) {
      await viewModel.reload(serviceID: 0)
    }
  }
}
