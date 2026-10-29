import SwiftUI

struct LiveCommentRow: View {
  @Environment(\.themePalette) var palette
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
