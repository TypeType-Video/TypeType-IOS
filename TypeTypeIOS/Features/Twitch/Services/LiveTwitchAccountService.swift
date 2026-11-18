import Foundation

protocol LiveTwitchAccountServiceProtocol {
  func account() async throws -> LiveTwitchAccountStatus
  func startLink() async throws -> LiveTwitchDeviceCode
  func pollLink(deviceCode: String) async throws -> LiveTwitchDevicePoll
  func unlink() async throws
  func followedLive(after: String?) async throws -> LiveTwitchPage<LiveTwitchStream>
  func followedVideos(after: String?) async throws -> LiveTwitchPage<LiveTwitchVideo>
  func followedChannels(after: String?) async throws -> LiveTwitchPage<LiveTwitchUser>
  func follow(login: String) async throws -> LiveTwitchFollowState
  func setFollow(login: String, following: Bool) async throws -> LiveTwitchFollowState
  func userEmotes(login: String) async throws -> LiveTwitchUserEmotes
  func chatAssets(login: String?) async throws -> LiveTwitchChatAssets
  func highlights(login: String) async throws -> LiveTwitchChatHighlights
  func send(_ message: String, login: String) async -> LiveTwitchChatSendResult
  func vote(pollID: String, choiceID: String) async -> LiveTwitchVoteResult
  func videoComments(id: String, request: LiveTwitchVodChatWindow.Request) async throws -> LiveTwitchPage<LiveTwitchVideoComment>
}

struct LiveTwitchAccountService: LiveTwitchAccountServiceProtocol {
  let apiClient: APIClient

  func account() async throws -> LiveTwitchAccountStatus {
    try await request(endpoint("/twitch/account", .get))
  }

  func startLink() async throws -> LiveTwitchDeviceCode {
    try await request(endpoint("/twitch/account/device", .post))
  }

  func pollLink(deviceCode: String) async throws -> LiveTwitchDevicePoll {
    try await request(endpoint("/twitch/account/poll", .post, body: try APIEndpoint.jsonBody(["deviceCode": deviceCode])))
  }

  func unlink() async throws {
    try await apiClient.request(endpoint("/twitch/account", .delete))
  }

  func followedLive(after: String?) async throws -> LiveTwitchPage<LiveTwitchStream> {
    try await request(endpoint("/twitch/me/live", .get, page: after))
  }

  func followedVideos(after: String?) async throws -> LiveTwitchPage<LiveTwitchVideo> {
    try await request(endpoint("/twitch/me/videos", .get, page: after))
  }

  func followedChannels(after: String?) async throws -> LiveTwitchPage<LiveTwitchUser> {
    try await request(endpoint("/twitch/me/follows", .get, page: after))
  }

  func follow(login: String) async throws -> LiveTwitchFollowState {
    try await request(endpoint("/twitch/me/follows/\(LiveTwitchService.segment(login))", .get))
  }

  func setFollow(login: String, following: Bool) async throws -> LiveTwitchFollowState {
    try await request(endpoint("/twitch/me/follows/\(LiveTwitchService.segment(login))", following ? .put : .delete))
  }

  func userEmotes(login: String) async throws -> LiveTwitchUserEmotes {
    try await request(endpoint("/twitch/me/emotes/\(LiveTwitchService.segment(login))", .get))
  }

  func chatAssets(login: String?) async throws -> LiveTwitchChatAssets {
    let path = login.map { "/twitch/chat/\(LiveTwitchService.segment($0))/assets" } ?? "/twitch/chat/assets"
    return try await request(APIEndpoint(path: path, method: .get))
  }

  func highlights(login: String) async throws -> LiveTwitchChatHighlights {
    try await request(APIEndpoint(path: "/twitch/chat/\(LiveTwitchService.segment(login))/highlights", method: .get))
  }

  func send(_ message: String, login: String) async -> LiveTwitchChatSendResult {
    do {
      let body = try APIEndpoint.jsonBody(["message": message])
      _ = try await apiClient.requestData(endpoint("/twitch/chat/\(LiveTwitchService.segment(login))/messages", .post, body: body))
      return .sent
    } catch let NetworkError.statusCode(_, message, reason) {
      return message == "chat_rejected" ? .rejected(reason: reason) : .failed
    } catch {
      return .failed
    }
  }

  // Twitch answers TOKENS_REQUIRED once the free vote is spent: further votes cost channel points.
  func vote(pollID: String, choiceID: String) async -> LiveTwitchVoteResult {
    do {
      let body = try APIEndpoint.jsonBody(["pollId": pollID, "choiceId": choiceID])
      _ = try await apiClient.requestData(endpoint("/twitch/polls/vote", .post, body: body))
      return .counted
    } catch let NetworkError.statusCode(_, _, code) {
      return code == "TOKENS_REQUIRED" ? .freeVoteSpent : .failed
    } catch {
      return .failed
    }
  }

  func videoComments(id: String, request at: LiveTwitchVodChatWindow.Request) async throws -> LiveTwitchPage<LiveTwitchVideoComment> {
    let item: URLQueryItem = switch at {
    case let .offset(seconds): URLQueryItem(name: "offset", value: String(Int(seconds.rounded(.down))))
    case let .cursor(cursor): URLQueryItem(name: "cursor", value: cursor)
    }
    return try await request(APIEndpoint(path: "/twitch/videos/\(LiveTwitchService.segment(id))/comments", method: .get, queryItems: [item]))
  }

  private func request<Value: Decodable>(_ endpoint: APIEndpoint) async throws -> Value {
    try await apiClient.request(endpoint, as: Value.self)
  }

  // `page` is the cursor of a paged list: nil for its first page, absent for a single answer.
  private func endpoint(_ path: String, _ method: HTTPMethod, body: Data? = nil, page: String?? = .none) -> APIEndpoint {
    var items = [URLQueryItem]()
    if case let .some(after) = page {
      items.append(URLQueryItem(name: "first", value: String(LiveTwitchService.pageSize)))
      if let after, !after.isEmpty { items.append(URLQueryItem(name: "after", value: after)) }
    }
    return APIEndpoint(path: path, method: method, queryItems: items, body: body, requiresAuth: true, retriesTransientFailures: false)
  }
}
