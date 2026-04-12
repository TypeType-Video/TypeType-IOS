import Foundation

struct ContinueWatchingItem: Identifiable, Hashable {
  let id: String
  let url: String
  let title: String
  let thumbnail: String
  let channelName: String
  let duration: Int64
  let progress: Int64

  var progressRatio: Double {
    guard duration > 0 else { return 0 }
    return min(1.0, max(0, Double(progress) / Double(duration)))
  }

  init(history: HistoryEntry) {
    id = history.id
    url = history.url
    title = history.title
    thumbnail = history.thumbnail
    channelName = history.channelName
    duration = history.duration
    progress = history.progress
  }
}
