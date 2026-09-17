import Foundation

enum LivePlaybackChapterNavigator {
  static func currentIndex(
    in chapters: [LivePlaybackChapter],
    at position: TimeInterval
  ) -> Int? {
    guard !chapters.isEmpty else { return nil }
    let index = chapters.lastIndex { chapter in
      position >= TimeInterval(chapter.startTimeSeconds)
    }
    return chapters.indices.contains(index ?? -1) ? index : nil
  }

  static func seekTarget(for chapter: LivePlaybackChapter) -> TimeInterval {
    max(0, TimeInterval(chapter.startTimeSeconds))
  }

  static func timeText(for chapter: LivePlaybackChapter) -> String {
    let total = max(0, chapter.startTimeSeconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
  }
}
