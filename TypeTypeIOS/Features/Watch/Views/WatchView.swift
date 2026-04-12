import SwiftUI

struct WatchView: View {
  let videoURL: String
  let coordinator: RootCoordinator
  private let watchService: WatchServiceProtocol
  private let watchProgressService: WatchProgressServiceProtocol
  private let watchActionsService: WatchActionsServiceProtocol
  @StateObject private var viewModel: WatchViewModel
  @StateObject private var actionsViewModel: WatchActionsViewModel
  @Environment(\.scenePhase) private var scenePhase

  init(
    videoURL: String,
    coordinator: RootCoordinator,
    watchService: WatchServiceProtocol,
    watchProgressService: WatchProgressServiceProtocol,
    watchActionsService: WatchActionsServiceProtocol
  ) {
    self.coordinator = coordinator
    self.videoURL = videoURL
    self.watchService = watchService
    self.watchProgressService = watchProgressService
    self.watchActionsService = watchActionsService
    _viewModel = StateObject(
      wrappedValue: WatchViewModel(
        videoURL: videoURL,
        watchService: watchService,
        progressService: watchProgressService
      )
    )
    _actionsViewModel = StateObject(
      wrappedValue: WatchActionsViewModel(videoURL: videoURL, service: watchActionsService)
    )
  }

  var body: some View {
    content
      .navigationTitle("Watch")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await viewModel.load()
        await viewModel.loadInitialComments()
      }
      .onChange(of: scenePhase) { _, phase in
        guard phase == .inactive || phase == .background else { return }
        Task { await viewModel.saveProgressNow() }
      }
      .onDisappear {
        Task { await viewModel.persistOnDisappear() }
      }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading && viewModel.stream == nil {
      ProgressView("Loading video...")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    } else if let errorMessage = viewModel.errorMessage {
      ContentUnavailableView(
        "Unable to open video",
        systemImage: "exclamationmark.triangle",
        description: Text(errorMessage)
      )
      .frame(maxHeight: .infinity)
    } else if let stream = viewModel.stream {
      WatchContentView(
        stream: stream,
        videoURL: videoURL,
        resumePositionMs: viewModel.resumePositionMs,
        actionsViewModel: actionsViewModel,
        coordinator: coordinator,
        watchService: watchService,
        watchProgressService: watchProgressService,
        watchActionsService: watchActionsService,
        relatedVideos: viewModel.relatedVideos,
        comments: viewModel.comments,
        isLoadingComments: viewModel.isLoadingComments,
        canLoadMoreComments: viewModel.canLoadMoreComments,
        isSavingProgress: viewModel.isSavingProgress,
        onTimeUpdate: viewModel.updatePlayback(positionMs:),
        onPause: {
          Task { await viewModel.pausePlayback() }
        },
        onEnded: viewModel.markCompleted,
        onPlayerError: { message in
          viewModel.errorMessage = message
        },
        onLoadMoreComments: {
          Task { await viewModel.loadMoreComments() }
        }
      )
    }
  }
}
