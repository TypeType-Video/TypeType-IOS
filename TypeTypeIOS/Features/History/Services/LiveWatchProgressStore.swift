import Foundation

/// Watch progress for every thumbnail's resume bar: seeded from history and kept fresh by playback,
/// so cards never fetch it themselves.
final class LiveWatchProgressStore: ObservableObject {
  @Published private(set) var fractions: [String: Double] = [:]

  func fraction(forVideoID videoID: String) -> Double? {
    guard !videoID.isEmpty else { return nil }
    return fractions[videoID]
  }

  func seed(fromHistory items: [LiveHistoryItem]) {
    for item in items {
      let fraction = item.progressFraction
      guard fraction > 0 else { continue }
      if !item.url.isEmpty {
        fractions[item.url] = fraction
      }
      if !item.id.isEmpty {
        fractions[item.id] = fraction
      }
    }
  }

  func update(
    videoID: String,
    positionMilliseconds: Int64,
    durationMilliseconds: Int64?
  ) {
    guard !videoID.isEmpty,
      let duration = durationMilliseconds,
      duration > 0
    else { return }
    let fraction = min(
      max(Double(positionMilliseconds) / Double(duration), 0),
      1
    )
    // A watched-through video loses the bar again, like the history page.
    guard fraction > 0 else {
      fractions.removeValue(forKey: videoID)
      return
    }
    fractions[videoID] = fraction
  }
}
