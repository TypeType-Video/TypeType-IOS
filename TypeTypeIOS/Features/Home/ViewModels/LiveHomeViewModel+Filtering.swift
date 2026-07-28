import Foundation

extension LiveHomeViewModel {
  static func inProgress(
    _ items: [LiveHistoryItem]
  ) -> [LiveHistoryItem] {
    var seen: Set<String> = []
    return items
      .filter { item in
        guard item.progress > 0, item.duration > 0 else {
          return false
        }
        let watched = item.duration > 60
          ? item.progress >= item.duration - 60
          : Double(item.progress) >= Double(item.duration) * 0.9
        return !watched
      }
      .sorted { $0.watchedAt > $1.watchedAt }
      .filter { seen.insert($0.video.canonicalID).inserted }
      .prefix(12)
      .map { $0 }
  }

  static func uniqueVisibleVideos(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter { video in
      return seen.insert(video.canonicalID).inserted
    }
  }

  static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Recommendations could not be loaded."
  }
}
