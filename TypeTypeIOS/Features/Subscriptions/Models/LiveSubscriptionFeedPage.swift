import Foundation

struct LiveSubscriptionFeedPage: Decodable, Equatable {
  let videos: [LiveVideoItem]
  let nextPage: String?
  let generation: Int64?
  let generatedAt: Int64?
  let refreshing: Bool

  init(
    videos: [LiveVideoItem],
    nextPage: String?,
    generation: Int64? = nil,
    generatedAt: Int64? = nil,
    refreshing: Bool = false
  ) {
    self.videos = videos
    self.nextPage = nextPage
    self.generation = generation
    self.generatedAt = generatedAt
    self.refreshing = refreshing
  }

  private enum CodingKeys: String, CodingKey {
    case videos
    case nextPage = "nextpage"
    case generation
    case generatedAt
    case refreshing
  }
}

struct LiveSubscriptionFeedPreparing: Decodable {
  let code: String
  let retryAfterMilliseconds: Int64

  private enum CodingKeys: String, CodingKey {
    case code
    case retryAfterMilliseconds = "retryAfterMs"
  }
}
