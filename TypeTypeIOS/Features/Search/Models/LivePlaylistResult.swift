import Foundation

struct LivePlaylistResult: Decodable, Hashable, Identifiable {
  let id: String
  let title: String
  let url: String
  let thumbnailURL: String
  let uploaderName: String
  let streamCount: Int64
  let playlistType: String

  var canonicalID: String {
    url.isEmpty ? id : url
  }

  var thumbnail: URL? {
    URL(string: thumbnailURL)
  }

  init(
    id: String,
    title: String,
    url: String,
    thumbnailURL: String,
    uploaderName: String,
    streamCount: Int64,
    playlistType: String
  ) {
    self.id = id
    self.title = title
    self.url = url
    self.thumbnailURL = thumbnailURL
    self.uploaderName = uploaderName
    self.streamCount = streamCount
    self.playlistType = playlistType
  }

  // One hole in a playlist row must not fail the whole page decode.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    uploaderName = try container.decodeIfPresent(String.self, forKey: .uploaderName) ?? ""
    streamCount = try container.decodeIfPresent(Int64.self, forKey: .streamCount) ?? 0
    playlistType = try container.decodeIfPresent(String.self, forKey: .playlistType) ?? ""
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case title
    case url
    case thumbnailURL = "thumbnailUrl"
    case uploaderName
    case streamCount
    case playlistType
  }
}
