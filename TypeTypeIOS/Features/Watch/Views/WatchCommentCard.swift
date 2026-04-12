import SwiftUI

struct WatchCommentCard: View {
  let comment: WatchComment

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
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
      }

      Text(comment.text)
        .font(.footnote)
        .lineLimit(4)

      Text("\(comment.publishedTime) • \(comment.likeCount) likes")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .padding(10)
    .background(TypeTypeColor.card)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}
