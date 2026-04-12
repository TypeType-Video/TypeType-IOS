import Foundation

struct YoutubeImportStats: Decodable {
  let imported: Int
  let skipped: Int
  let failed: Int
}

struct YoutubeImportReport: Decodable {
  let subscriptions: YoutubeImportStats
  let playlists: YoutubeImportStats
  let playlistItems: YoutubeImportStats
  let favorites: YoutubeImportStats
  let watchLater: YoutubeImportStats
  let history: YoutubeImportStats
  let warnings: [String]
  let errors: [String]
  let finishedAt: Int64
}
