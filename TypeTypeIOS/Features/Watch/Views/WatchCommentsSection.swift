import SwiftUI

struct WatchCommentsSection: View {
  let comments: [WatchComment]
  let commentsDisabled: Bool
  let videoURL: String
  let repliesFor: (String) -> [WatchComment]
  let isLoadingRepliesFor: (String) -> Bool
  let canLoadMoreRepliesFor: (String, String?) -> Bool
  let onLoadReplies: (WatchComment) -> Void
  let isLoading: Bool
  let canLoadMore: Bool
  let onLoadMore: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Comments")
        .font(.headline)

      if commentsDisabled {
        Text("Comments are disabled for this video.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else if comments.isEmpty, isLoading {
        ProgressView("Loading comments...")
      } else if comments.isEmpty {
        Text("No comments yet")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(comments.prefix(8)) { comment in
          WatchCommentCard(
            comment: comment,
            videoURL: videoURL,
            replies: repliesFor(comment.id),
            isLoadingReplies: isLoadingRepliesFor(comment.id),
            canLoadMoreReplies: canLoadMoreRepliesFor(comment.id, comment.repliesPage),
            onLoadReplies: { onLoadReplies(comment) }
          )
        }

        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity)
        } else if canLoadMore {
          Button("Load more comments") {
            onLoadMore()
          }
          .buttonStyle(.bordered)
        }
      }
    }
  }
}
