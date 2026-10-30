import SwiftUI

struct LiveCommentsSectionView: View {
  @Environment(\.themePalette) var palette
  let videoURL: String
  let dependencies: AppDependencies
  let onChannel: (String) -> Void
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  @StateObject private var viewModel: LiveCommentsViewModel

  init(
    videoURL: String,
    dependencies: AppDependencies,
    onChannel: @escaping (String) -> Void,
    onSeekTimestamp: @escaping (Double) -> Void,
    onOpenURL: @escaping (URL) -> Void
  ) {
    self.videoURL = videoURL
    self.dependencies = dependencies
    self.onChannel = onChannel
    self.onSeekTimestamp = onSeekTimestamp
    self.onOpenURL = onOpenURL
    _viewModel = StateObject(
      wrappedValue: LiveCommentsViewModel(
        videoURL: videoURL,
        commentsService: dependencies.commentsService,
        settingsService: dependencies.settingsService
      )
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Comments")
        .font(.title3.weight(.bold))

      content
    }
    .task { await viewModel.prepare() }
    .accessibilityIdentifier("live.comments.section")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      VStack(alignment: .leading, spacing: 14) {
        ForEach(0..<4, id: \.self) { _ in
          HStack(alignment: .top, spacing: 10) {
            TypeTypeSkeleton(cornerRadius: 18)
              .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 6) {
              TypeTypeSkeleton(cornerRadius: 4)
                .frame(width: 120, height: 10)
              TypeTypeSkeleton(cornerRadius: 4)
                .frame(height: 10)
              TypeTypeSkeleton(cornerRadius: 4)
                .frame(width: 220, height: 10)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 4)
      .accessibilityLabel("Loading comments")
    case .hidden:
      statusCard(
        title: "Hidden by your settings",
        message: "Comments and danmaku are disabled in your TypeType preferences.",
        systemImage: "eye.slash"
      ) {
        Button("Show for this video") {
          Task { await viewModel.reload(ignoringPreference: true) }
        }
      }
    case .disabled:
      statusCard(
        title: "Comments unavailable",
        message: "Comments are disabled for this video.",
        systemImage: "text.bubble"
      )
    case let .failed(message):
      statusCard(
        title: "Comments unavailable",
        message: message,
        systemImage: "wifi.exclamationmark"
      ) {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      if viewModel.comments.isEmpty {
        statusCard(
          title: "No comments",
          message: "There are no comments to display yet.",
          systemImage: "bubble.left"
        )
      } else {
        LazyVStack(alignment: .leading, spacing: 18) {
          ForEach(viewModel.comments) { comment in
            LiveCommentRow(
              comment: comment,
              videoURL: videoURL,
              service: dependencies.commentsService,
              onChannel: onChannel,
              onSeekTimestamp: onSeekTimestamp,
              onOpenURL: onOpenURL
            )
            Divider()
          }
          LiveIncrementalLoadingTrigger(
            canLoadMore: viewModel.canLoadMore,
            isLoading: viewModel.isLoadingMore,
            label: "Loading more comments",
            identifier: "live.comments.loading-more"
          ) {
            Task { await viewModel.loadMore() }
          }
        }
      }
    }
  }
}
