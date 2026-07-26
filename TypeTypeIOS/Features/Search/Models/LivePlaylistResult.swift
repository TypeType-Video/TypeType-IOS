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
