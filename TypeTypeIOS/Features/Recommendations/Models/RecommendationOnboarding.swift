import Foundation

struct RecommendationOnboardingTopicGroup: Decodable, Identifiable {
  let id: String
  let label: String
  let topics: [String]
}

struct RecommendationOnboardingTopicsResponse: Decodable {
  let minTopics: Int
  let groups: [RecommendationOnboardingTopicGroup]
}

struct RecommendationOnboardingStateResponse: Decodable {
  let requiresOnboarding: Bool
  let completedAt: Int64?
  let selectedTopics: [String]
  let selectedChannels: [String]
}
