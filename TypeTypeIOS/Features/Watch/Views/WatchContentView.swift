import SwiftUI

struct WatchContentView: View {
  let stream: WatchStream
  let videoURL: String
  let resumePositionMs: Int64
  @ObservedObject var actionsViewModel: WatchActionsViewModel
  let watchService: WatchServiceProtocol
  let watchProgressService: WatchProgressServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  let recommendationFeedbackService: RecommendationFeedbackServiceProtocol
  let relatedVideos: [HomeVideoItem]
  let coordinator: RootCoordinator
  let comments: [WatchComment]
  let commentsDisabled: Bool
  let repliesFor: (String) -> [WatchComment]
  let isLoadingRepliesFor: (String) -> Bool
  let canLoadMoreRepliesFor: (String, String?) -> Bool
  let isLoadingComments: Bool
  let canLoadMoreComments: Bool
  let isSavingProgress: Bool
  let onTimeUpdate: (Int64) -> Void
  let onPause: () -> Void
  let onEnded: () -> Void
  let onPlayerError: (String) -> Void
  let onLoadReplies: (WatchComment) -> Void
  let onLoadMoreComments: () -> Void
  @State private var latestObservedPositionMs: Int64 = 0

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        WatchPlayerView(
          stream: stream,
          initialPositionMs: resumePositionMs,
          onTimeUpdate: { positionMs in
            latestObservedPositionMs = max(0, positionMs)
            onTimeUpdate(positionMs)
          },
          onPause: {
            onPause()
            Task {
              await recommendationFeedbackService.sendEvent(
                type: .watch,
                videoURL: videoURL,
                uploaderURL: stream.uploaderUrl,
                title: stream.title,
                watchRatio: watchRatio,
                watchDurationMs: latestObservedPositionMs
              )
            }
          },
          onEnded: {
            onEnded()
            Task {
              await recommendationFeedbackService.sendEvent(
                type: .watch,
                videoURL: videoURL,
                uploaderURL: stream.uploaderUrl,
                title: stream.title,
                watchRatio: 1.0,
                watchDurationMs: latestObservedPositionMs
              )
            }
          },
          onError: onPlayerError
        )

        Text(stream.title)
          .font(.title3.weight(.semibold))

        Text(stream.uploaderName)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        WatchMetaRow(stream: stream)

        WatchFormatBadges(stream: stream)

        WatchActionsBar(actionsViewModel: actionsViewModel) {
          Task {
            await recommendationFeedbackService.sendFeedback(
              type: .notInterested,
              videoURL: videoURL,
              uploaderURL: stream.uploaderUrl
            )
            actionsViewModel.message = "Thanks, we will show less like this"
          }
        }

        if let message = actionsViewModel.message {
          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if stream.requiresMembership {
          Label("Member-only content", systemImage: "person.2.badge.key")
            .font(.caption)
            .foregroundStyle(.orange)
        }

        if !stream.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(stream.description)
            .font(.body)
            .foregroundStyle(.secondary)
        }

        WatchExternalLinks(videoURL: videoURL, uploaderURL: stream.uploaderUrl)

        WatchCommentsSection(
          comments: comments,
          commentsDisabled: commentsDisabled,
          videoURL: videoURL,
          repliesFor: repliesFor,
          isLoadingRepliesFor: isLoadingRepliesFor,
          canLoadMoreRepliesFor: canLoadMoreRepliesFor,
          onLoadReplies: onLoadReplies,
          isLoading: isLoadingComments,
          canLoadMore: canLoadMoreComments,
          onLoadMore: onLoadMoreComments
        )

        WatchRelatedSection(
          related: relatedVideos,
          coordinator: coordinator,
          watchService: watchService,
          watchProgressService: watchProgressService,
          watchActionsService: watchActionsService
        )

        NavigationLink {
          ChannelView(channelURL: stream.uploaderUrl, coordinator: coordinator)
        } label: {
          Label("Open Channel", systemImage: "person.crop.square")
        }
        .buttonStyle(.bordered)

        if isSavingProgress {
          HStack(spacing: 6) {
            ProgressView()
              .controlSize(.small)
            Text("Saving progress...")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
      .padding()
    }
    .task(id: stream.id) {
      latestObservedPositionMs = max(resumePositionMs, 0)
      actionsViewModel.prepare(stream: stream)
      await actionsViewModel.refresh()
      await recommendationFeedbackService.sendEvent(
        type: .impression,
        videoURL: videoURL,
        uploaderURL: stream.uploaderUrl,
        title: stream.title,
        watchRatio: nil,
        watchDurationMs: nil
      )
    }
  }

  private var watchRatio: Double {
    guard stream.duration > 0 else { return 0 }
    let durationMs = Double(stream.duration * 1_000)
    guard durationMs > 0 else { return 0 }
    let ratio = Double(max(0, latestObservedPositionMs)) / durationMs
    return min(1, max(0, ratio))
  }
}
