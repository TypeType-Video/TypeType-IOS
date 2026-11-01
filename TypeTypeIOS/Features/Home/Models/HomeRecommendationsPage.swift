import Foundation

struct HomeRecommendationsPage: Decodable, Equatable {
  struct Row: Decodable, Equatable {
    let id: String
  }

  let items: [LiveVideoItem]
  let nextCursor: String?
  let hasMore: Bool
  var rows: [Row]? = nil

  // Rows come only with a page the recommender built; the standard page has none and takes no feedback.
  var comesFromRecommender: Bool {
    rows != nil
  }
}
