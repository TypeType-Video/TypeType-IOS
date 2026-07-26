import Foundation

struct Int64OrString: Decodable, Hashable {
  let raw: Int64

  init(_ raw: Int64) {
    self.raw = raw
  }

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
    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Expected an Int64 or a decimal string."
    )
  }
}
