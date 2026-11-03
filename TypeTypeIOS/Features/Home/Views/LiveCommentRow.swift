import SwiftUI

struct LiveCommentRow: View {
  @Environment(\.themePalette) var palette
  let comment: LiveCommentItem
  @ObservedObject var threads: LiveCommentThreads
  let onChannel: (String) -> Void
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  private var thread: LiveCommentThreads.Thread {
    threads.thread(for: comment)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 11) {
      LiveRemoteImage(url: comment.authorAvatar)
        .frame(width: 38, height: 38)
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 7) {
        authorLine

        InteractiveText(
          text: comment.displayText,
          font: .body,
          lineLimit: nil,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
          .foregroundStyle(.primary)
          .textSelection(.enabled)

        badges

        if comment.replyCount > 0 {
          repliesControl
        }

        if thread.isVisible {
          repliesList
        }

        if let errorMessage = thread.errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var repliesControl: some View {
    Button {
      Task { await threads.toggle(comment) }
    } label: {
      HStack(spacing: 7) {
        if thread.isLoading {
          ProgressView()
            .controlSize(.small)
        }
        if thread.isVisible {
          Text("Hide replies")
        } else if comment.replyCount == 1 {
          Text("\(comment.replyCount) reply")
        } else {
          Text("\(comment.replyCount) replies")
        }
      }
      .font(.subheadline.weight(.semibold))
    }
    .disabled(thread.isLoading || comment.repliesPage?.isEmpty != false)
  }

  private var repliesList: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(thread.replies) { reply in
        LiveCommentReplyRow(
          comment: reply,
          onChannel: onChannel,
          onSeekTimestamp: onSeekTimestamp,
          onOpenURL: onOpenURL
        )
      }
      if thread.nextPage?.isEmpty == false {
        Button("Load more replies") {
          Task { await threads.loadMore(comment) }
        }
        .disabled(thread.isLoading)
      }
    }
    .padding(.leading, 4)
    .padding(.top, 3)
  }
}
