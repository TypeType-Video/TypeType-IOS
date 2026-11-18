import Foundation

protocol LiveRecommenderServiceProtocol {
  func algorithms() async throws -> LiveRecommenderAlgorithms
  func settings() async throws -> LiveRecommenderSettings
  func save(_ settings: LiveRecommenderSettings) async throws -> LiveRecommenderSettings
  func data() async throws -> [LiveRecommenderDataCategory]
  func lastHome() async throws -> LiveRecommenderTrace?
  func opinions() async throws -> [LiveRecommenderOpinion]
}

struct LiveRecommenderService: LiveRecommenderServiceProtocol {
  let apiClient: APIClient

  func algorithms() async throws -> LiveRecommenderAlgorithms {
    let query = [
      URLQueryItem(name: "locale", value: Locale.current.language.languageCode?.identifier ?? "en"),
      URLQueryItem(name: "timezone", value: TimeZone.current.identifier),
    ]
    return try await get("/recommendations/algorithms", query: query)
  }

  func settings() async throws -> LiveRecommenderSettings {
    try await get("/recommendations/settings")
  }

  func save(_ settings: LiveRecommenderSettings) async throws -> LiveRecommenderSettings {
    let endpoint = APIEndpoint(
      path: "/recommendations/settings", method: .put, body: try APIEndpoint.jsonBody(settings),
      requiresAuth: true, retriesTransientFailures: false
    )
    return try await apiClient.request(endpoint, as: LiveRecommenderSettings.self)
  }

  func data() async throws -> [LiveRecommenderDataCategory] {
    try await get("/recommendations/data")
  }

  func lastHome() async throws -> LiveRecommenderTrace? {
    do {
      return try await get("/recommendations/last-home")
    } catch NetworkError.statusCode(404, _, _) {
      return nil
    }
  }

  func opinions() async throws -> [LiveRecommenderOpinion] {
    try await get("/recommendations/feedback")
  }

  private func get<Value: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Value {
    try await apiClient.request(APIEndpoint(path: path, method: .get, queryItems: query, requiresAuth: true), as: Value.self)
  }
}
