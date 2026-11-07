import Foundation

enum LiveSearchResultMapper {
  static func uniqueVisibleResults(
    from page: LiveSearchPage,
    hidingShorts: Bool = false
  ) -> [LiveSearchResult] {
    unique(results(from: page, hidingShorts: hidingShorts))
  }

  static func results(
    from page: LiveSearchPage,
    hidingShorts: Bool = false
  ) -> [LiveSearchResult] {
    page.channels.map(LiveSearchResult.channel)
      + page.playlists.map(LiveSearchResult.playlist)
      + page.items.hidingShorts(hidingShorts)
        .map(LiveSearchResult.video)
  }

  static func unique(
    _ candidates: [LiveSearchResult]
  ) -> [LiveSearchResult] {
    var seen: Set<String> = []
    return candidates.filter { seen.insert($0.id).inserted }
  }

  static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Search could not be completed."
  }
}
