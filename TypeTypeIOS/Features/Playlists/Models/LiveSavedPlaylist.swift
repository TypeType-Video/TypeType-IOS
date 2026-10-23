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

  // A single null or missing field in a row must not fail the page decode:
  // playlist and channel responses carry deleted or members-only entries
  // with holes, and one bad row used to take the whole list down.

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
    publicPlaylistID = try container.decodeIfPresent(String.self, forKey: .publicPlaylistID) ?? ""
    url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    uploaderName = try container.decodeIfPresent(String.self, forKey: .uploaderName) ?? ""
    streamCount = try container.decodeIfPresent(Int64.self, forKey: .streamCount) ?? 0
    playlistType = try container.decodeIfPresent(String.self, forKey: .playlistType) ?? ""
    savedAt = try container.decodeIfPresent(Int64.self, forKey: .savedAt) ?? 0
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
