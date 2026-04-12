import SwiftUI

struct WatchCommentRepliesSection: View {
  let videoURL: String
  let replies: [WatchComment]
  let isLoadingReplies: Bool
  let canLoadMoreReplies: Bool
  let onLoadMoreReplies: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if replies.isEmpty, isLoadingReplies {
        ProgressView("Loading replies...")
          .font(.caption)
      } else {
        ForEach(replies.prefix(6)) { reply in
          WatchReplyCard(comment: reply)
        }

        if isLoadingReplies {
          ProgressView()
            .controlSize(.small)
        } else if canLoadMoreReplies {
          Button("Load more replies") {
            onLoadMoreReplies()
          }
          .buttonStyle(.plain)
          .font(.caption)
          .foregroundStyle(TypeTypeColor.accent)
        }
      }
    }
    .padding(.leading, 12)
    .overlay(alignment: .leading) {
      Rectangle()
        .fill(TypeTypeColor.accent.opacity(0.35))
        .frame(width: 2)
    }
  }
}
