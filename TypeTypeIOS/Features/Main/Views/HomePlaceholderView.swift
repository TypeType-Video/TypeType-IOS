import SwiftUI

struct HomePlaceholderView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: HomeFeedViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: HomeFeedViewModel(
        homeService: coordinator.dependencies.homeFeedService,
        libraryService: coordinator.dependencies.libraryService
      )
    )
  }

  @ViewBuilder
  private var continueWatchingSection: some View {
    if !viewModel.continueWatching.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("Continue Watching")
          .font(.headline)
          .padding(.horizontal)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 10) {
            ForEach(viewModel.continueWatching) { item in
              NavigationLink {
                WatchView(
                  videoURL: item.url,
                  watchService: coordinator.dependencies.watchService,
                  watchProgressService: coordinator.dependencies.watchProgressService,
                  watchActionsService: coordinator.dependencies.watchActionsService
                )
              } label: {
                ContinueWatchingCardView(item: item)
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal)
        }
      }
      .padding(.top, 2)
    }
  }

  @ViewBuilder
  private var header: some View {
    ZStack(alignment: .bottomLeading) {
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            colors: [TypeTypeColor.accent.opacity(0.95), TypeTypeColor.accent.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      VStack(alignment: .leading, spacing: 6) {
        if let server = coordinator.selectedServer {
          Text(server.name)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
          Text(server.baseURLString)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
        }
        if let session = coordinator.currentSession {
          Text("Signed in as \(session.userEmail)")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.92))
        }
      }
      .padding(14)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 104)
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
    } else if viewModel.videos.isEmpty {
      ContentUnavailableView(
        "No videos available",
        systemImage: "play.rectangle.on.rectangle",
        description: Text("Pull to refresh or try another server.")
      )
    } else {
      List {
        continueWatchingSection
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)

        ForEach(viewModel.videos) { video in
          NavigationLink {
            WatchView(
              videoURL: video.url,
              watchService: coordinator.dependencies.watchService,
              watchProgressService: coordinator.dependencies.watchProgressService,
              watchActionsService: coordinator.dependencies.watchActionsService
            )
          } label: {
            HomeVideoRowView(video: video)
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(TypeTypeColor.background)
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
