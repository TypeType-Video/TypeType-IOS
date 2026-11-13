import SwiftUI

struct LiveCommentReplyRow: View {
  let comment: LiveCommentItem
  let voice: LiveCommentVoicePlayer
  let animatesGIFs: Bool
  let onChannel: (String) -> Void
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 9) {
      LiveRemoteImage(url: comment.authorAvatar)
        .frame(width: 30, height: 30)
        .clipShape(Circle())
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
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
          if !comment.publishedDisplay.isEmpty {
            Text(comment.publishedDisplay)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        InteractiveText(
          text: comment.displayText,
          font: .subheadline,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
          .foregroundStyle(.primary)
          .textSelection(.enabled)
        LiveCommentAttachments(comment: comment, voice: voice, animatesGIFs: animatesGIFs)
      }
    }
  }
}
