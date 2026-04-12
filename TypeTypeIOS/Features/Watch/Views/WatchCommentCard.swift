import SwiftUI

struct WatchCommentCard: View {
  let comment: WatchComment
  let videoURL: String
  let replies: [WatchComment]
  let isLoadingReplies: Bool
  let canLoadMoreReplies: Bool
  let onLoadReplies: () -> Void

  @State private var isExpanded: Bool = false
  @State private var showReplies: Bool = false

  private var likesText: String {
    let textual = comment.textualLikeCount.trimmingCharacters(in: .whitespacesAndNewlines)
    return textual.isEmpty ? "\(comment.likeCount) likes" : "\(textual) likes"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      header

      Text(comment.text)
        .font(.footnote)
        .lineLimit(isExpanded ? nil : 5)

      if comment.text.count > 160 {
        Button(isExpanded ? "Show less" : "Show more") {
          isExpanded.toggle()
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(TypeTypeColor.accent)
      }

      Text("\(comment.publishedTime) • \(likesText)")
        .font(.caption2)
        .foregroundStyle(.secondary)

      if comment.repliesPage != nil {
        Button(showReplies ? "Hide replies" : "Show replies (\(comment.replyCount))") {
          showReplies.toggle()
          if showReplies, replies.isEmpty {
            onLoadReplies()
          }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(TypeTypeColor.accent)
      }

      if showReplies {
        WatchCommentRepliesSection(
          videoURL: videoURL,
          replies: replies,
          isLoadingReplies: isLoadingReplies,
          canLoadMoreReplies: canLoadMoreReplies,
          onLoadMoreReplies: onLoadReplies
        )
      }
    }
    .padding(10)
    .background(TypeTypeColor.card)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }

  private var header: some View {
    HStack(spacing: 6) {
      Text(comment.author)
        .font(.caption.weight(.semibold))
      if comment.uploaderVerified {
        Image(systemName: "checkmark.seal.fill")
          .font(.caption2)
          .foregroundStyle(TypeTypeColor.accent)
      }
      if comment.isPinned {
        Text("PINNED")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.orange)
      }
      Spacer(minLength: 0)
    }
  }
}
