import Foundation

// Once the scroll rests, prepares the cards in view, so a tap starts from what is already prepared.
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
  private let prefetch: @MainActor (LiveVideoItem) async -> Void
  private var cards: [UUID: Placement] = [:]
  private var videos: [UUID: LiveVideoItem] = [:]
  private var movedAt = ContinuousClock.now
  private var settleTask: Task<Void, Never>?
  private var prefetchTask: Task<Void, Never>?

  init(
    settleDelay: Duration = .milliseconds(500),
    prefetch: @escaping @MainActor (LiveVideoItem) async -> Void
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
    videos[id] = video
    guard cards[id] != placement else { return }
    cards[id] = placement
    moved()
  }

  func remove(_ id: UUID) {
    videos[id] = nil
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
    var picked: [LiveVideoItem] = []
    for (id, card) in cards
      .filter({ $0.value.visibleFraction >= Self.minimumVisibleFraction })
      .sorted(by: { ($0.value.visibleFraction, -$0.value.top) > ($1.value.visibleFraction, -$1.value.top) })
    where !picked.contains(where: { $0.url == card.videoURL }) {
      guard let video = videos[id] else { continue }
      picked.append(video)
      if picked.count == Self.maximumCards { break }
    }
    guard !picked.isEmpty else { return }
    let prefetch = prefetch
    prefetchTask = Task {
      for video in picked {
        guard !Task.isCancelled else { return }
        await prefetch(video)
      }
    }
  }
}
