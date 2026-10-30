import SwiftUI

extension LiveCommentRow {
  var authorLine: some View {
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
          .foregroundStyle(palette.accent)
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
  var badges: some View {
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
}
