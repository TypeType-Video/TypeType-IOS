import SwiftUI

struct LiveCommentsSectionView: View {
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
      HStack(spacing: 10) {
        ProgressView()
        Text("Loading comments")
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
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
          DemoIncrementalLoadingTrigger(
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

  private func statusCard<Actions: View>(
    title: String,
    message: String,
    systemImage: String,
    @ViewBuilder actions: () -> Actions
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)
      actions()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      DemoTheme.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }

  private func statusCard<Actions: View>(
    title: LocalizedStringKey,
    message: LocalizedStringKey,
    systemImage: String,
    @ViewBuilder actions: () -> Actions
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)
      actions()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      DemoTheme.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }

  private func statusCard(
    title: LocalizedStringKey,
    message: LocalizedStringKey,
    systemImage: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(message)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      DemoTheme.surface,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }

  private func statusCard(
    title: String,
    message: String,
    systemImage: String
  ) -> some View {
    statusCard(
      title: title,
      message: message,
      systemImage: systemImage
    ) {
      EmptyView()
    }
  }
}

private struct LiveCommentRow: View {
  let comment: LiveCommentItem
  let videoURL: String
  let service: LiveCommentsServiceProtocol
  let onChannel: (String) -> Void
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  @State private var replies: [LiveCommentItem] = []
  @State private var nextRepliesPage: String?
  @State private var isLoadingReplies = false
  @State private var repliesVisible = false
  @State private var errorMessage: String?

  var body: some View {
    HStack(alignment: .top, spacing: 11) {
      LiveRemoteImage(url: comment.authorAvatar)
        .frame(width: 38, height: 38)
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 7) {
        authorLine

        InteractiveText(
          text: comment.displayText,
          font: .body,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
          .foregroundStyle(.primary)
          .textSelection(.enabled)

        badges

        if comment.replyCount > 0 {
          repliesControl
        }

        if repliesVisible {
          repliesList
        }

        if let errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var authorLine: some View {
    HStack(spacing: 5) {
      Button {
        guard !comment.authorURL.isEmpty else { return }
        onChannel(comment.authorURL)
      } label: {
        Text(comment.author)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
      }
      .buttonStyle(.plain)
      .disabled(comment.authorURL.isEmpty)

      if comment.uploaderVerified {
        Image(systemName: "checkmark.seal.fill")
          .font(.caption2)
          .foregroundStyle(DemoTheme.accent)
          .accessibilityLabel("Verified")
      }

      Spacer(minLength: 4)

      if !comment.publishedDisplay.isEmpty {
        Text(comment.publishedDisplay)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private var badges: some View {
    HStack(spacing: 12) {
      if comment.isPinned {
        Label("Pinned", systemImage: "pin.fill")
      }
      if comment.isHeartedByUploader {
        Label("Creator heart", systemImage: "heart.fill")
          .foregroundStyle(.red)
      }
      if comment.likeCount > 0 || !comment.textualLikeCount.isEmpty {
        Label(
          comment.textualLikeCount.isEmpty
            ? String(comment.likeCount)
            : comment.textualLikeCount,
          systemImage: "hand.thumbsup"
        )
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }

  private var repliesControl: some View {
    Button {
      if repliesVisible {
        repliesVisible = false
      } else if replies.isEmpty {
        Task { await loadReplies(reset: true) }
      } else {
        repliesVisible = true
      }
    } label: {
      HStack(spacing: 7) {
        if isLoadingReplies {
          ProgressView()
            .controlSize(.small)
        }
        if repliesVisible {
          Text("Hide replies")
        } else if comment.replyCount == 1 {
          Text("\(comment.replyCount) reply")
        } else {
          Text("\(comment.replyCount) replies")
        }
      }
      .font(.subheadline.weight(.semibold))
    }
    .disabled(isLoadingReplies || comment.repliesPage?.isEmpty != false)
  }

  private var repliesList: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(replies) { reply in
        LiveCommentReplyRow(
          comment: reply,
          onChannel: onChannel,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
      }
      if nextRepliesPage?.isEmpty == false {
        Button("Load more replies") {
          Task { await loadReplies(reset: false) }
        }
        .disabled(isLoadingReplies)
      }
    }
    .padding(.leading, 4)
    .padding(.top, 3)
  }

  @MainActor
  private func loadReplies(reset: Bool) async {
    guard !isLoadingReplies else { return }
    let pageToken = reset ? comment.repliesPage : nextRepliesPage
    guard let pageToken, !pageToken.isEmpty else { return }
    isLoadingReplies = true
    errorMessage = nil
    defer { isLoadingReplies = false }
    do {
      let page = try await service.replies(
        url: videoURL,
        repliesPage: pageToken
      )
      if reset {
        replies = page.comments
      } else {
        let existing = Set(replies.map(\.id))
        replies.append(contentsOf: page.comments.filter {
          !existing.contains($0.id)
        })
      }
      nextRepliesPage = page.nextPage
      repliesVisible = true
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription
        ?? String(localized: "Replies could not be loaded.")
    }
  }
}

private struct LiveCommentReplyRow: View {
  let comment: LiveCommentItem
  let onChannel: (String) -> Void
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 9) {
      LiveRemoteImage(url: comment.authorAvatar)
        .frame(width: 30, height: 30)
        .clipShape(Circle())
      VStack(alignment: .leading, spacing: 4) {
        Button {
          guard !comment.authorURL.isEmpty else { return }
          onChannel(comment.authorURL)
        } label: {
          Text(comment.author)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .disabled(comment.authorURL.isEmpty)
        InteractiveText(
          text: comment.displayText,
          font: .subheadline,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
          .foregroundStyle(.primary)
          .textSelection(.enabled)
      }
    }
  }
}
