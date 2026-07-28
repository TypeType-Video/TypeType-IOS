import Foundation

struct LivePipePipeRestoreResult: Decodable, Equatable {
  let history: Int
  let subscriptions: Int
  let playlists: Int
  let playlistVideos: Int
  let progress: Int
  let searchHistory: Int
  let timeMode: String
  let historyMinWatchedAt: Int64?
  let historyMaxWatchedAt: Int64?
}

struct LiveYouTubeImportJob: Decodable, Equatable {
  let jobID: String
  let status: String
  let phase: String
  let progress: Int
  let createdAt: Int64
  let updatedAt: Int64
  let expiresAt: Int64
  let error: String?

  private enum CodingKeys: String, CodingKey {
    case jobID = "jobId"
    case status, phase, progress, createdAt, updatedAt, expiresAt, error
  }
}

struct LiveYouTubeImportCounts: Decodable, Equatable {
  let subscriptions: Int
  let playlists: Int
  let playlistItems: Int
  let favorites: Int
  let watchLater: Int
  let history: Int
}

struct LiveYouTubeImportPreview: Decodable, Equatable {
  let counts: LiveYouTubeImportCounts
  let dedup: LiveYouTubeImportCounts
  let warnings: [String]
  let errors: [String]
}

struct LiveYouTubeImportCommit: Encodable {
  var importSubscriptions = true
  var importPlaylists = true
  var importPlaylistItems = true
  var importFavorites = true
  var importWatchLater = true
  var importHistory = true
}

struct LiveYouTubeImportStats: Decodable, Equatable {
  let imported: Int
  let skipped: Int
  let failed: Int
}

struct LiveYouTubeImportReport: Decodable, Equatable {
  let subscriptions: LiveYouTubeImportStats
  let playlists: LiveYouTubeImportStats
  let playlistItems: LiveYouTubeImportStats
  let favorites: LiveYouTubeImportStats
  let watchLater: LiveYouTubeImportStats
  let history: LiveYouTubeImportStats
  let warnings: [String]
  let errors: [String]
  let finishedAt: Int64
}

struct LiveYouTubeImportArchive: Identifiable, Equatable {
  enum State: Equatable {
    case queued
    case uploading
    case previewing
    case committing
    case importing
    case completed
    case failed(String)
  }

  let id: UUID
  let url: URL
  let fileName: String
  var state: State
  var progress: Int
  var job: LiveYouTubeImportJob?
  var preview: LiveYouTubeImportPreview?
  var report: LiveYouTubeImportReport?

  init(url: URL) {
    id = UUID()
    self.url = url
    fileName = url.lastPathComponent
    state = .queued
    progress = 0
  }
}
