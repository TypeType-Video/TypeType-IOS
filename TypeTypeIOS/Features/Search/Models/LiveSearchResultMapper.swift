import Foundation

enum LiveSearchResultMapper {
  static func uniqueVisibleResults(
    from page: LiveSearchPage
  ) -> [LiveSearchResult] {
    unique(results(from: page))
  }

  static func results(
    from page: LiveSearchPage
  ) -> [LiveSearchResult] {
    page.channels.map(LiveSearchResult.channel)
      + page.playlists.map(LiveSearchResult.playlist)
      + page.items
        .filter { !$0.isShortFormContent }
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
