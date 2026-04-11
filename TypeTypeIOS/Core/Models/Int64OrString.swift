import Foundation

struct Int64OrString: Decodable, Hashable {
  let raw: Int64

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(Int64.self) {
      raw = value
      return
    }
    if let text = try? container.decode(String.self), let value = Int64(text) {
      raw = value
      return
    }
    raw = 0
  }
}
