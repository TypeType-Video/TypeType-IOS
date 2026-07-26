import SwiftUI

struct DemoWatchCommentRow: View {
  let comment: DemoWatchComment
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void
  @State private var showsReplies = false
  @State private var isLiked = false
  @State private var isDisliked = false
  @State var isExpanded = false
  @State private var presentsReply = false
  @State private var replyText = ""
  @State private var localReplies: [String] = []

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      avatar

      VStack(alignment: .leading, spacing: 7) {
        authorLine
        message
        actionBar

        if !comment.replies.isEmpty || !localReplies.isEmpty {
          repliesButton
        }

        if showsReplies {
          DemoWatchCommentReplies(
            replies: comment.replies,
            localReplies: localReplies,
            onSeekTimestamp: onSeekTimestamp,
            onOpenURL: onOpenURL
          )
        }
      }
    }
    .alert("Reply to \(comment.author)", isPresented: $presentsReply) {
      TextField("Write a reply", text: $replyText)
      Button("Post", action: postReply)
      Button("Cancel", role: .cancel) {
        replyText = ""
      }
    }
  }

  private var avatar: some View {
    Circle()
      .fill(
        LinearGradient(
          colors: [.red, .purple],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: 38, height: 38)
      .overlay {
        Text(String(comment.author.dropFirst().prefix(1)).uppercased())
          .font(.caption.weight(.bold))
      }
  }

  private var authorLine: some View {
    HStack(spacing: 6) {
      Text(comment.author)
        .font(.caption.weight(.semibold))
      if comment.isVerified {
        Image(systemName: "checkmark.seal.fill")
          .font(.caption2)
          .foregroundStyle(Color(red: 1, green: 0.31, blue: 0.34))
      }
      if comment.isPinned {
        Label("Pinned", systemImage: "pin.fill")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Text(comment.detail)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private var message: some View {
    VStack(alignment: .leading, spacing: 5) {
      DemoInteractiveText(
        text: comment.message,
        font: .subheadline,
        lineLimit: isExpanded ? nil : 5,
        onSeekTimestamp: onSeekTimestamp,
        onOpenURL: onOpenURL
      )

      if comment.message.count > 180 {
        Button(isExpanded ? "Show less" : "Show more") {
          withAnimation(.snappy) {
            isExpanded.toggle()
          }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      }
    }
  }

  private var actionBar: some View {
    HStack(spacing: 16) {
      Button {
        isLiked.toggle()
        if isLiked {
          isDisliked = false
        }
      } label: {
        Label(
          isLiked ? "\(comment.likeCount) + 1" : comment.likeCount,
          systemImage: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
        )
      }

      Button {
        isDisliked.toggle()
        if isDisliked {
          isLiked = false
        }
      } label: {
        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
      }

      Button("Reply") {
        presentsReply = true
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .buttonStyle(.plain)
  }

  private var repliesButton: some View {
    Button {
      withAnimation(.snappy) {
        showsReplies.toggle()
      }
    } label: {
      Label(
        showsReplies ? "Hide replies" : replyCountLabel,
        systemImage: showsReplies ? "chevron.up" : "chevron.down"
      )
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.44))
    .buttonStyle(.plain)
  }

  private var replyCountLabel: String {
    let count = comment.replies.count + localReplies.count
    return "\(count) repl\(count == 1 ? "y" : "ies")"
  }

  private func postReply() {
    let value = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return }
    localReplies.append(value)
    replyText = ""
    showsReplies = true
  }
}
