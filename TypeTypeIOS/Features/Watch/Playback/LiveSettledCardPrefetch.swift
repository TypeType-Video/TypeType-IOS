import Foundation

// Once the scroll rests, fetches the playback stream of the cards in view, so a tap starts from the cache.
@MainActor
final class LiveSettledCardPrefetch {
  struct Placement: Equatable {
    let videoURL: String
    let visibleFraction: Double
    let top: Double
  }

  static let minimumVisibleFraction = 0.5
  static let maximumCards = 2

  private let settleDelay: Duration
  private let prefetch: @MainActor (String) async -> Void
  private var cards: [UUID: Placement] = [:]
  private var movedAt = ContinuousClock.now
  private var settleTask: Task<Void, Never>?
  private var prefetchTask: Task<Void, Never>?

  init(
    settleDelay: Duration = .milliseconds(600),
    prefetch: @escaping @MainActor (String) async -> Void
  ) {
    self.settleDelay = settleDelay
    self.prefetch = prefetch
  }

  func place(_ id: UUID, video: LiveVideoItem, visibleFraction: Double, top: Double) {
    guard !video.isLive, !video.url.isEmpty else {
      remove(id)
      return
    }
    let placement = Placement(videoURL: video.url, visibleFraction: visibleFraction, top: top)
    guard cards[id] != placement else { return }
    cards[id] = placement
    moved()
  }

  func remove(_ id: UUID) {
    guard cards.removeValue(forKey: id) != nil else { return }
    moved()
  }

  private func moved() {
    movedAt = .now
    prefetchTask?.cancel()
    prefetchTask = nil
    guard settleTask == nil else { return }
    settleTask = Task { [weak self] in
      while let self {
        let quiet = ContinuousClock.now - movedAt
        guard quiet < settleDelay else {
          settleTask = nil
          prefetchMostVisible()
          return
        }
        try? await Task.sleep(for: settleDelay - quiet)
      }
    }
  }

  private func prefetchMostVisible() {
    var urls: [String] = []
    for card in cards.values
      .filter({ $0.visibleFraction >= Self.minimumVisibleFraction })
      .sorted(by: { ($0.visibleFraction, -$0.top) > ($1.visibleFraction, -$1.top) })
    where !urls.contains(card.videoURL) {
      urls.append(card.videoURL)
      if urls.count == Self.maximumCards { break }
    }
    guard !urls.isEmpty else { return }
    let prefetch = prefetch
    prefetchTask = Task {
      for url in urls {
        guard !Task.isCancelled else { return }
        await prefetch(url)
      }
    }
  }
}
