import Foundation

protocol LiveLinkedAccountsServiceProtocol {
  func startYouTubeLogin() async throws -> LiveYouTubeDeviceLogin
  func pollYouTubeLogin() async throws -> LiveYouTubeDevicePoll
  func cancelYouTubeLogin() async throws
  func biliBiliState() async throws -> LiveBiliBiliSessionState
  func startBiliBiliLogin() async throws -> LiveBiliBiliQRLogin
  func pollBiliBiliLogin(key: String) async throws -> LiveBiliBiliQRPoll
  func disconnectBiliBili() async throws
}

struct LiveLinkedAccountsService: LiveLinkedAccountsServiceProtocol {
  let apiClient: APIClient

  private struct Status: Decodable {
    let status: String
  }

  func startYouTubeLogin() async throws -> LiveYouTubeDeviceLogin {
    try await apiClient.request(endpoint("/youtube-session/device/start", .post), as: LiveYouTubeDeviceLogin.self)
  }

  func pollYouTubeLogin() async throws -> LiveYouTubeDevicePoll {
    LiveYouTubeDevicePoll(status: try await apiClient.request(endpoint("/youtube-session/device/status", .get), as: Status.self).status)
  }

  func cancelYouTubeLogin() async throws {
    try await apiClient.request(endpoint("/youtube-session/device/cancel", .post))
  }

  func biliBiliState() async throws -> LiveBiliBiliSessionState {
    LiveBiliBiliSessionState(status: try await apiClient.request(endpoint("/bilibili-session/status", .get), as: Status.self).status)
  }

  func startBiliBiliLogin() async throws -> LiveBiliBiliQRLogin {
    try await apiClient.request(endpoint("/bilibili-session/qr", .post), as: LiveBiliBiliQRLogin.self)
  }

  func pollBiliBiliLogin(key: String) async throws -> LiveBiliBiliQRPoll {
    let poll = APIEndpoint(
      path: "/bilibili-session/qr/poll",
      method: .post,
      body: try APIEndpoint.jsonBody(["qrcodeKey": key]),
      requiresAuth: true,
      retriesTransientFailures: false
    )
    return LiveBiliBiliQRPoll(status: try await apiClient.request(poll, as: Status.self).status)
  }

  func disconnectBiliBili() async throws {
    try await apiClient.request(endpoint("/bilibili-session", .delete))
  }

  private func endpoint(_ path: String, _ method: HTTPMethod) -> APIEndpoint {
    APIEndpoint(path: path, method: method, requiresAuth: true, retriesTransientFailures: false)
  }
}
