import Foundation

struct YoutubeImportCounts: Decodable {
  let subscriptions: Int
  let playlists: Int
  let playlistItems: Int
  let favorites: Int
  let watchLater: Int
  let history: Int
}

struct YoutubeImportPreview: Decodable {
  let counts: YoutubeImportCounts
  let dedup: YoutubeImportCounts
  let warnings: [String]
  let errors: [String]
}
