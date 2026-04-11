import Foundation

struct SearchPageResult: Decodable {
  let items: [HomeVideoItem]
  let nextpage: String?
  let searchSuggestion: String?
  let isCorrectedSearch: Bool
}
