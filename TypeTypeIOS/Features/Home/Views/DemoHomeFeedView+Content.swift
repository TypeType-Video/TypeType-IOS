import SwiftUI

extension DemoHomeFeedView {
  var continueWatching: some View {
    VStack(alignment: .leading, spacing: 13) {
      DemoSectionLabel(title: "Continue watching")
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 14) {
          ForEach(visibleContinueWatching) { video in
            Button {
              select(video)
            } label: {
              DemoContinueCard(video: video)
            }
            .buttonStyle(.plain)
          }
        }
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.viewAligned)
    }
  }

  var recommendations: some View {
    VStack(alignment: .leading, spacing: 14) {
      DemoSectionLabel(title: "Recommended")
      if visibleRecommendations.isEmpty {
        ContentUnavailableView {
          Label(
            session.isInstanceAllowListRestricted
              ? "No family recommendations yet"
              : "No recommendations",
            systemImage: "rectangle.stack.badge.person.crop"
          )
        } actions: {
          Button("Allow Blender Studio") {
            if !session.globalAllowedChannels.contains("Blender Studio") {
              session.globalAllowedChannels.append("Blender Studio")
            }
          }
          .buttonStyle(.borderedProminent)
        }
      } else {
        LazyVStack(spacing: 10) {
          ForEach(visibleRecommendations.prefix(recommendationLimit)) { video in
            DemoCompactVideoRow(
              video: video,
              identifier: "demo.home.video.\(video.id)",
              showsChannel: true,
              onSelect: select
            )

            if video.id != visibleRecommendations.prefix(recommendationLimit).last?.id {
              Divider()
                .padding(.leading, 160)
            }
          }

          LiveIncrementalLoadingTrigger(
            canLoadMore: recommendationLimit < visibleRecommendations.count,
            isLoading: isLoadingMore,
            label: "Loading more recommendations",
            identifier: "demo.home.recommendations.loading",
            action: loadMoreRecommendations
          )
        }
      }
    }
  }

  var visibleContinueWatching: [DemoVideo] {
    DemoMockCatalog.continueWatching.filter {
      session.playbackProgressVideoIDs.contains($0.id) && isVisible($0)
    }
  }

  var visibleRecommendations: [DemoVideo] {
    DemoMockCatalog.recommendations.filter(isVisible)
  }

  func isVisible(_ video: DemoVideo) -> Bool {
    !session.hiddenVideoIDs.contains(video.id)
      && !session.blockedVideoIDs.contains(video.id)
      && !session.blockedChannelNames.contains(video.channel)
      && (
        !session.isInstanceAllowListRestricted
          || session.globalAllowedChannels.contains(video.channel)
      )
  }

  func loadMoreRecommendations() {
    guard
      !isLoadingMore,
      recommendationLimit < visibleRecommendations.count
    else {
      return
    }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(450))
      recommendationLimit = min(
        visibleRecommendations.count,
        recommendationLimit + 3
      )
      isLoadingMore = false
    }
  }
}
