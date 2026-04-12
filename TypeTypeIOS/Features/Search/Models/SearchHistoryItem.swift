import Foundation

struct SearchHistoryItem: Decodable, Identifiable, Hashable {
  let id: String
  let term: String
  let searchedAt: Int64
}
