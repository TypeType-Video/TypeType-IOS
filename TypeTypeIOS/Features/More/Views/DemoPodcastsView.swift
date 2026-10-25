import SwiftUI

struct DemoPodcastsView: View {
  let podcast: DemoChannelPodcast?
  @State private var selectedVideo: DemoVideo?
  @State private var visibleCount = 3
  @State private var isLoadingMore = false

  init(podcast: DemoChannelPodcast? = nil) {
    self.podcast = podcast
  }

  var body: some View {
    List {
      Section {
        HStack(spacing: 16) {
          Image(artwork.rawValue)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 92, height: 92)
            .padding(10)
            .background(Color.purple.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 20))
          VStack(alignment: .leading, spacing: 5) {
            Text(title)
              .font(.title2.weight(.bold))
            Text(creator)
              .font(.subheadline)
              .foregroundStyle(.secondary)
            Text(summary)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 8)
      }

      Section {
        ForEach(episodes.prefix(visibleCount)) { episode in
          DemoVideoCard(video: episode.video(creator: creator, artwork: artwork)) {
            selectedVideo = $0
          }
          .listRowInsets(
            EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
          )
          .listRowBackground(Color.clear)
        }
        DemoIncrementalLoadingTrigger(
          canLoadMore: visibleCount < episodes.count,
          isLoading: isLoadingMore,
          label: "Loading more episodes",
          identifier: "demo.podcasts.loading",
          action: loadMore
        )
      } header: { Text("Episodes").liveSectionHeader() }
    }
      .listStyle(.insetGrouped)
    .navigationTitle("Podcasts")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(item: $selectedVideo) { video in
      DemoWatchView(video: video)
    }
    .accessibilityIdentifier("demo.podcasts.screen")
  }

  private var title: String {
    podcast?.title ?? "Open Playback"
  }

  private var creator: String {
    podcast?.creator ?? "TypeType & PipePipe"
  }

  private var artwork: DemoArtwork {
    podcast?.artwork ?? .pipePipe
  }

  private var summary: String {
    podcast == nil
      ? "Engineering an open video ecosystem."
      : "\(podcast?.episodeCount ?? episodes.count) mock episodes from this channel."
  }

  private var episodes: [DemoPodcastEpisode] {
    guard let podcast else { return DemoPodcastEpisode.all }
    return (0..<podcast.episodeCount).map { index in
      let source = DemoPodcastEpisode.all[index % DemoPodcastEpisode.all.count]
      let edition = index / DemoPodcastEpisode.all.count
      return DemoPodcastEpisode(
        id: "\(podcast.id)-\(index)-\(source.id)",
        title: edition == 0
          ? source.title
          : "\(source.title) · Follow-up \(edition + 1)",
        date: source.date,
        duration: source.duration
      )
    }
  }

  private func loadMore() {
    guard !isLoadingMore, visibleCount < episodes.count else { return }
    isLoadingMore = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(360))
      withAnimation(.smooth(duration: 0.25)) {
        visibleCount = min(visibleCount + 3, episodes.count)
      }
      try? await Task.sleep(for: .milliseconds(140))
      isLoadingMore = false
    }
  }
}
