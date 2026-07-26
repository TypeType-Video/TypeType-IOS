import Foundation

struct LiveSearchFilterOption: Decodable, Hashable, Identifiable {
  let value: String
  let label: String

  var id: String {
    value
  }

  var displayName: String {
    label
      .replacingOccurrences(of: "_", with: " ")
      .split(separator: " ")
      .map { word in
        word.prefix(1).uppercased() + word.dropFirst()
      }
      .joined(separator: " ")
  }
}

struct LiveSearchFilters: Decodable, Equatable {
  let contentFilters: [LiveSearchFilterOption]
  let sortFilters: [LiveSearchFilterOption]
}

struct LiveSearchPage: Decodable, Equatable {
  let items: [LiveVideoItem]
  let nextPage: String?
  let searchSuggestion: String?
  let isCorrectedSearch: Bool
  let playlists: [LivePlaylistResult]
  let channels: [LiveChannelResult]

  private enum CodingKeys: String, CodingKey {
    case items
    case nextPage = "nextpage"
    case searchSuggestion
    case isCorrectedSearch
    case playlists
    case channels
  }
}

struct LiveSearchHistoryItem: Decodable, Equatable, Identifiable {
  let id: String
  let term: String
  let searchedAt: Int64
}
