import Foundation

protocol LiveTwitchServiceProtocol {
  func streams(after: String?) async throws -> LiveTwitchPage<LiveTwitchStream>
  func games(after: String?) async throws -> LiveTwitchPage<LiveTwitchGame>
  func gameStreams(slug: String, after: String?) async throws -> LiveTwitchGameStreams
  func tagStreams(tag: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchStream>
  func channel(login: String) async throws -> LiveTwitchChannel
  func channelVideos(login: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchVideo>
  func channelClips(login: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchClip>
  func searchChannels(_ query: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchChannel>
  func searchGames(_ query: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchGame>
  func searchStreams(_ query: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchStream>
}

struct LiveTwitchService: LiveTwitchServiceProtocol {
  static let pageSize = 24

  let apiClient: APIClient

  func streams(after: String?) async throws -> LiveTwitchPage<LiveTwitchStream> {
    try await get("/twitch/streams", after: after)
  }

  func games(after: String?) async throws -> LiveTwitchPage<LiveTwitchGame> {
    try await get("/twitch/games", after: after)
  }

  func gameStreams(slug: String, after: String?) async throws -> LiveTwitchGameStreams {
    try await get("/twitch/games/\(Self.segment(slug))/streams", after: after)
  }

  func tagStreams(tag: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchStream> {
    try await get("/twitch/tags/\(Self.segment(tag))/streams", after: after)
  }

  func channel(login: String) async throws -> LiveTwitchChannel {
    try await apiClient.request(APIEndpoint(path: "/twitch/channels/\(Self.segment(login))", method: .get), as: LiveTwitchChannel.self)
  }

  func channelVideos(login: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchVideo> {
    try await get("/twitch/channels/\(Self.segment(login))/videos", after: after)
  }

  func channelClips(login: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchClip> {
    try await get("/twitch/channels/\(Self.segment(login))/clips", after: after)
  }

  func searchChannels(_ query: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchChannel> {
    try await search(query, kind: .channels, after: after)
  }

  func searchGames(_ query: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchGame> {
    try await search(query, kind: .games, after: after)
  }

  func searchStreams(_ query: String, after: String?) async throws -> LiveTwitchPage<LiveTwitchStream> {
    try await search(query, kind: .streams, after: after)
  }

  private func search<Item: Decodable>(
    _ query: String,
    kind: LiveTwitchSearchKind,
    after: String?
  ) async throws -> LiveTwitchPage<Item> {
    let extra = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "type", value: kind.rawValue)]
    return try await get("/twitch/search", after: after, extra: extra)
  }

  private func get<Value: Decodable>(_ path: String, after: String?, extra: [URLQueryItem] = []) async throws -> Value {
    var items = extra + [URLQueryItem(name: "first", value: String(Self.pageSize))]
    if let after, !after.isEmpty { items.append(URLQueryItem(name: "after", value: after)) }
    return try await apiClient.request(APIEndpoint(path: path, method: .get, queryItems: items), as: Value.self)
  }

  // URLSessionAPIClient sets URLComponents.path, which encodes spaces and accents itself; only a slash would split
  // the segment.
  static func segment(_ value: String) -> String {
    value.replacingOccurrences(of: "/", with: " ")
  }
}
