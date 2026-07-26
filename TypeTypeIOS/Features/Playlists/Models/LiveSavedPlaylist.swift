import Foundation

struct LiveSavedPlaylist: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let publicPlaylistID: String
  let url: String
  let title: String
  let thumbnailURL: String
  let uploaderName: String
  let streamCount: Int64
  let playlistType: String
  let savedAt: Int64

  var thumbnail: URL? { URL(string: thumbnailURL) }

  var searchResult: LivePlaylistResult {
    LivePlaylistResult(
      id: publicPlaylistID,
      title: title,
      url: url,
      thumbnailURL: thumbnailURL,
      uploaderName: uploaderName,
      streamCount: streamCount,
      playlistType: playlistType
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case publicPlaylistID = "publicPlaylistId"
    case url, title
    case thumbnailURL = "thumbnailUrl"
    case uploaderName, streamCount, playlistType, savedAt
  }
}

struct LiveSavePlaylistPayload: Encodable {
  let url: String
}

struct LivePublicPlaylistPage: Decodable, Equatable {
  let playlist: LivePlaylistResult
  let videos: [LiveVideoItem]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case playlist, videos
    case nextPage = "nextpage"
  }
}
