import Foundation

struct LiveAdminRecommenderStatus: Decodable, Equatable {
  struct Algorithm: Decodable, Equatable {
    let id: String
    let name: String
  }

  let installed: Bool
  let enabled: Bool
  let reachable: Bool
  let healthMs: Int?
  let algorithms: [Algorithm]
  let defaultAlgorithm: String?
  let pagesBuilt: Int
  let pagesFromCache: Int
  let fallbacks: Int
  let averageBuildMs: Double
  let sourceRequests: Int
  let sourceCacheHits: Int
  let streamRequests: Int
  let streamRequestsRefused: Int
}

struct LiveAdminRecommenderFeedback: Decodable, Equatable {
  struct Verdicts: Decodable, Equatable {
    let algorithmId: String
    let good: Int
    let bad: Int
    let notForMe: Int
  }

  struct Comment: Decodable, Equatable {
    let verdict: String
    let comment: String?
    let algorithmId: String
    let createdAt: Int64
  }

  let usersEnabled: Int
  let usersByAlgorithm: [String: Int]
  let verdicts: [Verdicts]
  let comments: [Comment]
}

struct LiveAdminRssFeed: Decodable, Equatable, Identifiable {
  struct Feed: Decodable, Equatable {
    let id: String
    let name: String
    let enabled: Bool
    let lastUsedAt: Int64?
  }

  let feed: Feed
  let userId: String
  let userName: String
  let userRssEnabled: Bool
  let userSuspended: Bool

  var id: String { feed.id }
}

struct LiveAdminRssFeedsPage: Decodable, Equatable {
  let items: [LiveAdminRssFeed]
  let page: Int
  let limit: Int
  let total: Int
}

struct LiveAdminNoticeRequest: Encodable, Equatable {
  let kind: String
  let message: String?
  let resumeInSeconds: Int?
}
