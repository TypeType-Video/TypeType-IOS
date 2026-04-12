import Foundation

struct BlockedItem: Decodable, Encodable, Identifiable, Hashable {
  let url: String
  let name: String?
  let thumbnailUrl: String?
  let blockedAt: Int64
  let global: Bool?

  var id: String { url }

  init(url: String, name: String? = nil, thumbnailUrl: String? = nil, blockedAt: Int64 = 0, global: Bool? = nil) {
    self.url = url
    self.name = name
    self.thumbnailUrl = thumbnailUrl
    self.blockedAt = blockedAt
    self.global = global
  }
}
