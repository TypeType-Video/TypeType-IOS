import Foundation

struct HomeRecommendationsPage: Decodable, Equatable {
  let items: [LiveVideoItem]
  let nextCursor: String?
  let hasMore: Bool
}
