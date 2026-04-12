import SwiftUI

struct WatchReplyCard: View {
  let comment: WatchComment

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(comment.author)
        .font(.caption.weight(.semibold))
      Text(comment.text)
        .font(.caption)
        .lineLimit(4)
      Text(comment.publishedTime)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .padding(8)
    .background(TypeTypeColor.background.opacity(0.55))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
