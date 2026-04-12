import Foundation

struct PipePipeRestoreSummary: Decodable {
  let history: Int
  let subscriptions: Int
  let playlists: Int
  let playlistVideos: Int
  let progress: Int
  let searchHistory: Int
  let timeMode: String
  let historyMinWatchedAt: Int64
  let historyMaxWatchedAt: Int64
}
