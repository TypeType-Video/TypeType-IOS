import Foundation

protocol LiveRecommenderFeedbackServiceProtocol {
  func refuse(_ video: LiveVideoItem) async throws -> String
  func withdraw(id: String) async throws
}

final class LiveRecommenderFeedbackService: LiveRecommenderFeedbackServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func refuse(_ video: LiveVideoItem) async throws -> String {
    let payload = LiveRecommenderFeedbackPayload(
      videoUrl: video.url,
      title: video.title.isEmpty ? nil : String(video.title.prefix(300)),
      channelName: video.uploaderName.isEmpty ? nil : String(video.uploaderName.prefix(300)),
      thumbnailUrl: video.thumbnailURL.isEmpty || video.thumbnailURL.count > 500 ? nil : video.thumbnailURL
    )
    return try await apiClient.request(
      APIEndpoint(
        path: "/recommendations/feedback",
        method: .post,
        body: try APIEndpoint.jsonBody(payload),
        requiresAuth: true
      ),
      as: LiveRecommenderFeedbackEntry.self
    ).id
  }

  func withdraw(id: String) async throws {
    let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(["/"])) ?? id
    do {
      try await apiClient.request(
        APIEndpoint(path: "/recommendations/feedback/\(encoded)", method: .delete, requiresAuth: true)
      )
    } catch NetworkError.statusCode(404, _) {
      return
    }
  }
}

private struct LiveRecommenderFeedbackPayload: Encodable {
  let kind = "video"
  let verdict = "not_for_me"
  let videoUrl: String
  let title: String?
  let channelName: String?
  let thumbnailUrl: String?
}

private struct LiveRecommenderFeedbackEntry: Decodable {
  let id: String
}
