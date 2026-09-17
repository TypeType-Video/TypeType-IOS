import Foundation

struct LiveBlockedKeywordItem: Codable, Equatable, Hashable, Identifiable {
  let keyword: String
  let blockedAt: Int64
  let global: Bool?

  var id: String { keyword }

  private enum CodingKeys: String, CodingKey {
    case keyword
    case blockedAt
    case global
  }

  init(
    keyword: String,
    blockedAt: Int64 = 0,
    global: Bool? = nil
  ) {
    self.keyword = keyword
    self.blockedAt = blockedAt
    self.global = global
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    keyword = try values.decode(String.self, forKey: .keyword)
    blockedAt = try values.decodeIfPresent(
      Int64.self,
      forKey: .blockedAt
    ) ?? 0
    global = try values.decodeIfPresent(Bool.self, forKey: .global)
  }
}
