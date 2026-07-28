import Foundation

extension LivePlaybackService {
  func bulletComments(
    for videoURL: String
  ) async throws -> [LiveBulletComment] {
    let page = try await apiClient.request(
      APIEndpoint(
        path: "/bullet-comments",
        method: .get,
        queryItems: [
          URLQueryItem(name: "url", value: videoURL)
        ],
        requiresAuth: true,
        timeoutInterval: 120
      ),
      as: LiveBulletCommentsPage.self
    )
    return page.comments.sorted {
      $0.durationMilliseconds < $1.durationMilliseconds
    }
  }
}
