import Foundation

@MainActor
final class LivePodcastEpisodesViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var podcast: LivePodcastItem
  @Published private(set) var episodes: [LiveVideoItem] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var canLoadMore = false

  private let service: LiveChannelServiceProtocol
  private var nextPage: String?

  init(
    podcast: LivePodcastItem,
    service: LiveChannelServiceProtocol
  ) {
    self.podcast = podcast
    self.service = service
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    nextPage = nil
    canLoadMore = false
    do {
      let page = try await service.podcastEpisodes(
        url: podcast.url,
        nextPage: nil
      )
      apply(page)
    } catch is CancellationError {
      return
    } catch {
      episodes = []
      state = .failed(Self.message(for: error))
    }
  }

  func loadMore() async {
    guard canLoadMore, !isLoadingMore else { return }
    guard let nextPage, !nextPage.isEmpty else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.podcastEpisodes(
        url: podcast.url,
        nextPage: nextPage
      )
      podcast = page.podcast
      episodes = Self.unique(episodes + page.episodes)
      self.nextPage = page.nextPage
      canLoadMore = page.nextPage?.isEmpty == false
      state = episodes.isEmpty ? .empty : .loaded
    } catch is CancellationError {
      return
    } catch {
      canLoadMore = true
    }
  }

  private func apply(_ page: LivePodcastEpisodesPage) {
    podcast = page.podcast
    episodes = Self.unique(page.episodes)
    nextPage = page.nextPage
    canLoadMore = page.nextPage?.isEmpty == false
    state = episodes.isEmpty ? .empty : .loaded
  }

  private static func unique(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter {
      seen.insert($0.canonicalID).inserted
    }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Podcast episodes could not be loaded."
  }
}
