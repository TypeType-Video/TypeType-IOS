import SwiftUI

struct WatchContentView: View {
  let stream: WatchStream
  let videoURL: String
  let resumePositionMs: Int64
  @ObservedObject var actionsViewModel: WatchActionsViewModel
  let watchService: WatchServiceProtocol
  let watchProgressService: WatchProgressServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  let relatedVideos: [HomeVideoItem]
  let comments: [WatchComment]
  let isLoadingComments: Bool
  let canLoadMoreComments: Bool
  let isSavingProgress: Bool
  let onTimeUpdate: (Int64) -> Void
  let onPause: () -> Void
  let onEnded: () -> Void
  let onPlayerError: (String) -> Void
  let onLoadMoreComments: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        WatchPlayerView(
          stream: stream,
          initialPositionMs: resumePositionMs,
          onTimeUpdate: onTimeUpdate,
          onPause: onPause,
          onEnded: onEnded,
          onError: onPlayerError
        )

        Text(stream.title)
          .font(.title3.weight(.semibold))

        Text(stream.uploaderName)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        WatchMetaRow(stream: stream)

        WatchFormatBadges(stream: stream)

        WatchActionsBar(actionsViewModel: actionsViewModel)

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
          isLoading: isLoadingComments,
          canLoadMore: canLoadMoreComments,
          onLoadMore: onLoadMoreComments
        )

        WatchRelatedSection(
          related: relatedVideos,
          watchService: watchService,
          watchProgressService: watchProgressService,
          watchActionsService: watchActionsService
        )

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
      actionsViewModel.prepare(stream: stream)
      await actionsViewModel.refresh()
    }
  }
}
