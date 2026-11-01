import SwiftUI

extension LiveHomeView {
  var recommendationsSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Recommended")
        .font(.headline)

      LazyVGrid(
        columns: [
          GridItem(
            .adaptive(minimum: 330, maximum: 520),
            spacing: 22,
            alignment: .top
          ),
        ],
        alignment: .leading,
        spacing: 24
      ) {
        LiveHiddenVideosReader(coordinator.dependencies.hiddenVideos) { hidden in
          ForEach(hidden.visible(viewModel.videos)) { video in
            if let refusal = refusals.state(for: video) {
              LiveRefusedRecommendationCard(
                state: refusal,
                onExplain: { reason in Task { await explainRefusal(video, reason: reason) } },
                onUndo: { Task { await undoRefusal(video) } }
              )
            } else {
              recommendationCard(video)
            }
          }
        }

        LiveIncrementalLoadingTrigger(
          canLoadMore: viewModel.canLoadMore,
          isLoading: viewModel.isLoadingMore,
          label: "Loading more recommendations",
          identifier: "live.home.loading-more"
        ) {
          Task { await viewModel.loadMore() }
        }
      }
      .animation(.smooth(duration: 0.25), value: refusals.states)
    }
  }

  private func recommendationCard(
    _ video: LiveVideoItem
  ) -> some View {
    LiveVideoCard(
      video: video,
      deArrowStore: coordinator.dependencies.deArrowStore,
      onChannel: {
        guard !video.uploaderURL.isEmpty else { return }
        selectedChannelURL = video.uploaderURL
      },
      action: {
        selectedVideo = video
      }
    )
    .liveVideoQuickActions(
      video: video,
      dependencies: coordinator.dependencies,
      onOpenChannel: {
        guard !video.uploaderURL.isEmpty else { return }
        selectedChannelURL = video.uploaderURL
      },
      onNotInterested: viewModel.offersNotInterested && refusals.isAvailable
        ? { Task { await refuse(video) } }
        : nil
    )
  }

  private func refuse(_ video: LiveVideoItem) async {
    if let failure = await refusals.refuse(video) {
      toasts?.show(failure, tone: .failure)
    }
  }

  private func explainRefusal(_ video: LiveVideoItem, reason: LiveRefusalReason) async {
    if let failure = await refusals.explain(video, reason: reason) {
      toasts?.show(failure, tone: .failure)
    }
  }

  private func undoRefusal(_ video: LiveVideoItem) async {
    if let failure = await refusals.undo(video) {
      toasts?.show(failure, tone: .failure)
    }
  }
}
