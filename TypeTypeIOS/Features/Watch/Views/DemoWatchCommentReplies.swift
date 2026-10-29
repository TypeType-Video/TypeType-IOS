import SwiftUI

struct DemoWatchCommentReplies: View {
  @Environment(\.themePalette) private var palette
  let replies: [DemoWatchReply]
  let localReplies: [String]
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(replies) { reply in
        replyRow(
          avatar: String(reply.author.dropFirst().prefix(1)).uppercased(),
          author: reply.author,
          message: reply.message,
          detail: reply.detail,
          isLocal: false
        )
      }
      ForEach(Array(localReplies.enumerated()), id: \.offset) { _, reply in
        replyRow(
          avatar: "T",
          author: "@typetype",
          message: reply,
          detail: "Just now · local",
          isLocal: true
        )
      }
    }
    .padding(.leading, 10)
    .overlay(alignment: .leading) {
      Rectangle()
        .fill(palette.separator)
        .frame(width: 1)
    }
  }

  private func replyRow(
    avatar: String,
    author: String,
    message: String,
    detail: String,
    isLocal: Bool
  ) -> some View {
    HStack(alignment: .top, spacing: 9) {
      Circle()
        .fill(
          isLocal
            ? Color(red: 1, green: 0.3, blue: 0.34).opacity(0.3)
            : palette.elevatedSurface
        )
        .frame(width: 28, height: 28)
        .overlay {
          Text(avatar).font(.caption2.weight(.bold))
        }
      VStack(alignment: .leading, spacing: 3) {
        Text(author)
          .font(.caption.weight(.semibold))
        InteractiveText(
          text: message,
          font: .caption,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
        Text(detail)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}
