import SwiftUI

struct WatchCommentsSection: View {
  let comments: [WatchComment]
  let isLoading: Bool
  let canLoadMore: Bool
  let onLoadMore: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Comments")
        .font(.headline)

      if comments.isEmpty, isLoading {
        ProgressView("Loading comments...")
      } else if comments.isEmpty {
        Text("No comments yet")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(comments.prefix(8)) { comment in
          WatchCommentCard(comment: comment)
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
