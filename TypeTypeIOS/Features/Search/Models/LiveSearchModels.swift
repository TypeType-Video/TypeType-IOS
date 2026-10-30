import Foundation

struct LiveSearchFilterOption: Decodable, Hashable, Identifiable {
  let value: String
  let label: String

  var id: String {
    value
  }

  var displayName: String {
    let value = label.split(separator: ":", maxSplits: 1).last.map(String.init) ?? label
    let trimmed = value.trimmingCharacters(in: .whitespaces)
    return Self.words(trimmed.hasPrefix("sort_") ? String(trimmed.dropFirst(5)) : trimmed)
  }

  var groupName: String? {
    guard label.contains(":"), let group = label.split(separator: ":").first else { return nil }
    let name = group == "sortby" ? "sort_by" : String(group)
    return Self.words(name)
  }

  private static func words(_ raw: String) -> String {
    raw.split(whereSeparator: { $0 == "_" || $0 == " " })
      .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
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
