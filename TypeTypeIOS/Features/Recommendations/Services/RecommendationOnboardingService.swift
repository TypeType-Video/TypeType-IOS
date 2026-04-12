import Foundation

protocol RecommendationOnboardingServiceProtocol {
  func topics() async throws -> RecommendationOnboardingTopicsResponse
  func state() async throws -> RecommendationOnboardingStateResponse
  func savePreferences(selectedTopics: [String], selectedChannels: [String]) async throws -> RecommendationOnboardingStateResponse
  func complete() async throws -> RecommendationOnboardingStateResponse
  func skip() async throws -> RecommendationOnboardingStateResponse
  func reapply() async throws -> RecommendationOnboardingStateResponse
}

private struct RecommendationOnboardingPreferencesRequest: Encodable {
  let selectedTopics: [String]
  let selectedChannels: [String]
}

final class RecommendationOnboardingService: RecommendationOnboardingServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func topics() async throws -> RecommendationOnboardingTopicsResponse {
    let endpoint = APIEndpoint(path: "/recommendations/onboarding/topics", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: RecommendationOnboardingTopicsResponse.self)
  }

  func state() async throws -> RecommendationOnboardingStateResponse {
    let endpoint = APIEndpoint(path: "/recommendations/onboarding/state", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: RecommendationOnboardingStateResponse.self)
  }

  func savePreferences(
    selectedTopics: [String],
    selectedChannels: [String]
  ) async throws -> RecommendationOnboardingStateResponse {
    let payload = RecommendationOnboardingPreferencesRequest(
      selectedTopics: Self.normalize(selectedTopics),
      selectedChannels: Self.normalize(selectedChannels)
    )
    let endpoint = APIEndpoint(
      path: "/recommendations/onboarding/preferences",
      method: .put,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(payload),
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: RecommendationOnboardingStateResponse.self)
  }

  func complete() async throws -> RecommendationOnboardingStateResponse {
    let endpoint = APIEndpoint(path: "/recommendations/onboarding/complete", method: .post, requiresAuth: true)
    return try await apiClient.request(endpoint, as: RecommendationOnboardingStateResponse.self)
  }

  func skip() async throws -> RecommendationOnboardingStateResponse {
    let endpoint = APIEndpoint(path: "/recommendations/onboarding/skip", method: .post, requiresAuth: true)
    return try await apiClient.request(endpoint, as: RecommendationOnboardingStateResponse.self)
  }

  func reapply() async throws -> RecommendationOnboardingStateResponse {
    let endpoint = APIEndpoint(path: "/recommendations/onboarding/reapply", method: .post, requiresAuth: true)
    return try await apiClient.request(endpoint, as: RecommendationOnboardingStateResponse.self)
  }

  private static func normalize(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    var output: [String] = []
    for raw in values {
      let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !value.isEmpty else { continue }
      let key = value.lowercased()
      guard !seen.contains(key) else { continue }
      seen.insert(key)
      output.append(value)
    }
    return output
  }
}
