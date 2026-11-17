import XCTest
@testable import TypeTypeIOS

final class LiveTwitchServiceTests: XCTestCase {
  func testDecodesAStreamPageAndAsksForTheNextCursor() async throws {
    let client = TwitchClient(body: Self.streamsPage)
    let page = try await LiveTwitchService(apiClient: client).streams(after: "abc")

    XCTAssertEqual(page.items.map(\.user.login), ["blender_org"])
    XCTAssertEqual(page.items.first?.game?.slug, "art")
    XCTAssertEqual(page.items.first?.tags, ["English", "Blender"])
    XCTAssertEqual(page.items.first?.viewers, 1_204)
    XCTAssertEqual(page.cursor, "next")
    XCTAssertTrue(page.hasMore)
    XCTAssertEqual(client.endpoint?.path, "/twitch/streams")
    XCTAssertEqual(client.query["first"], "24")
    XCTAssertEqual(client.query["after"], "abc")
  }

  func testSearchSendsTheQueryAndKind() async throws {
    let client = TwitchClient(body: #"{"items":[],"hasMore":false}"#)
    _ = try await LiveTwitchService(apiClient: client).searchGames("open movie", after: nil)

    XCTAssertEqual(client.endpoint?.path, "/twitch/search")
    XCTAssertEqual(client.query["q"], "open movie")
    XCTAssertEqual(client.query["type"], "games")
    XCTAssertNil(client.query["after"])
  }

  func testAChannelDecodesFromItsFlatUserFields() async throws {
    let client = TwitchClient(body: Self.channel)
    let channel = try await LiveTwitchService(apiClient: client).channel(login: "blender_org")

    XCTAssertEqual(client.endpoint?.path, "/twitch/channels/blender_org")
    XCTAssertEqual(channel.user.name, "blender_org")
    XCTAssertEqual(channel.followers, 12_411)
    XCTAssertNil(channel.live)
  }

  func testAGameStreamsAnswerKeepsItsGameAndPage() async throws {
    let client = TwitchClient(body: #"{"game":{"id":"1","name":"Art","slug":"art"},"streams":{"items":[],"hasMore":false}}"#)
    let answer = try await LiveTwitchService(apiClient: client).gameStreams(slug: "art", after: nil)

    XCTAssertEqual(client.endpoint?.path, "/twitch/games/art/streams")
    XCTAssertEqual(answer.game?.name, "Art")
    XCTAssertTrue(answer.streams.items.isEmpty)
  }

  func testASlashCannotSplitAPathSegment() {
    XCTAssertEqual(LiveTwitchService.segment("a/b"), "a b")
  }

  private static let streamsPage = #"""
    {"items":[{"id":"1","title":"Sculpting","user":{"id":"9","login":"blender_org","displayName":"blender_org","avatarUrl":""},
    "game":{"id":"2","name":"Art","slug":"art"},"viewers":1204,"previewUrl":"https://example.test/p.jpg",
    "startedAt":"2026-11-17T18:06:44Z","tags":["English","Blender"]}],"cursor":"next","hasMore":true}
    """#

  private static let channel = #"""
    {"id":"468562730","login":"blender_org","displayName":"blender_org","avatarUrl":"","description":"Blender",
    "followers":12411,"partner":false}
    """#
}

@MainActor
final class LiveTwitchPagedListTests: XCTestCase {
  func testLoadsMoreWithTheCursorAndDropsRepeatedItems() async throws {
    var cursors: [String?] = []
    let list = LiveTwitchPagedList<Item> { cursor in
      cursors.append(cursor)
      return cursor == nil
        ? LiveTwitchPage(items: [Item(id: "a"), Item(id: "b")], cursor: "2", hasMore: true)
        : LiveTwitchPage(items: [Item(id: "b"), Item(id: "c")], cursor: nil, hasMore: false)
    }

    await list.prepare()
    await list.loadMore()

    XCTAssertEqual(list.items.map(\.id), ["a", "b", "c"])
    XCTAssertEqual(cursors, [nil, "2"])
    XCTAssertFalse(list.canLoadMore)
  }

  func testAFailureShowsTheMessageAndAReloadRecovers() async {
    var fails = true
    let list = LiveTwitchPagedList<Item> { _ in
      if fails { throw NetworkError.statusCode(503, nil) }
      return LiveTwitchPage(items: [Item(id: "a")], cursor: nil, hasMore: false)
    }

    await list.prepare()
    guard case .failed = list.state else { return XCTFail("Expected a failure, got \(list.state)") }
    fails = false
    await list.reload()

    XCTAssertEqual(list.state, .loaded)
    XCTAssertEqual(list.items.map(\.id), ["a"])
  }

  private struct Item: Identifiable, Decodable {
    let id: String
  }
}

private final class TwitchClient: APIClient, @unchecked Sendable {
  let body: String
  var endpoint: APIEndpoint?

  init(body: String) {
    self.body = body
  }

  var query: [String: String] {
    Dictionary((endpoint?.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
  }

  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
    self.endpoint = endpoint
    return try JSONDecoder().decode(T.self, from: Data(body.utf8))
  }

  func request(_ endpoint: APIEndpoint) async throws {}

  func requestData(_ endpoint: APIEndpoint) async throws -> Data { Data() }
}

final class LiveTwitchLinkTests: XCTestCase {
  func testReadsChannelsBroadcastsAndClipsLikeTheWeb() {
    XCTAssertEqual(target("https://www.twitch.tv/Blender_Org"), .channel("blender_org"))
    XCTAssertEqual(target("https://m.twitch.tv/videos/2931565552"), .video("2931565552"))
    XCTAssertEqual(target("https://www.twitch.tv/blender_org/clip/SomeClip-abc_1"), .clip("SomeClip-abc_1"))
    XCTAssertEqual(target("https://clips.twitch.tv/SomeClip-abc_1"), .clip("SomeClip-abc_1"))
    XCTAssertEqual(target("https://watch.example.test/twitch/watch?c=blender_org"), .channel("blender_org"))
    XCTAssertEqual(target("https://watch.example.test/twitch/channel/blender_org"), .channel("blender_org"))
  }

  func testIgnoresTwitchPagesThatAreNotAChannelOrAVideo() {
    XCTAssertNil(target("https://www.twitch.tv/directory"))
    XCTAssertNil(target("https://www.twitch.tv/settings"))
    XCTAssertNil(target("https://www.twitch.tv/videos/not-a-number"))
    XCTAssertNil(target("https://example.test/watch?c=blender_org"))
  }

  func testAChannelLinkOpensItsPageAndABroadcastPlays() {
    if case .twitch(.channel("blender_org"))? = resolve("https://www.twitch.tv/blender_org") {} else { XCTFail("Expected the channel") }
    if case let .video(video)? = resolve("https://www.twitch.tv/videos/2931565552") {
      XCTAssertEqual(video.url, "https://www.twitch.tv/videos/2931565552")
    } else {
      XCTFail("Expected the broadcast to play")
    }
    let shared = "typetype://open?url=" + ("https://www.twitch.tv/blender_org".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")
    if case .twitch(.channel("blender_org"))? = resolve(shared) {} else { XCTFail("Expected the shared channel") }
  }

  private func target(_ text: String) -> LiveTwitchLink? {
    URL(string: text).flatMap(LiveTwitchLink.target(for:))
  }

  private func resolve(_ text: String) -> LiveMediaLinkDestination? {
    URL(string: text).flatMap { LiveMediaLinkResolver.destination(for: $0) }
  }
}

@MainActor
final class LiveTwitchLiveSessionTests: XCTestCase {
  func testReloadsALiveThatStaysStalledAndStopsAfterTheLastAttempt() async throws {
    let recovery = LiveTwitchLiveSession(firstDelay: 0.01, longestDelay: 0.01)
    var reloads = 0
    for _ in 0..<(LiveTwitchLiveSession.maximumAttempts + 2) {
      recovery.stalled(stillStalled: { true }, reload: { reloads += 1 })
      try await Task.sleep(for: .milliseconds(60))
    }

    XCTAssertEqual(reloads, LiveTwitchLiveSession.maximumAttempts)
  }

  func testAStallThatEndsByItselfReloadsNothingAndPlayingStartsOver() async throws {
    let recovery = LiveTwitchLiveSession(firstDelay: 0.01, longestDelay: 0.01)
    var reloads = 0
    recovery.stalled(stillStalled: { false }, reload: { reloads += 1 })
    try await Task.sleep(for: .milliseconds(60))
    recovery.stalled(stillStalled: { true }, reload: { reloads += 1 })
    try await Task.sleep(for: .milliseconds(60))
    recovery.playing()

    XCTAssertEqual(reloads, 1)
    XCTAssertEqual(recovery.attempts, 0)
  }
}

final class LiveTwitchPlaybackTests: XCTestCase {
  func testBuildsABroadcastStreamAtTheRootOfTheInstance() throws {
    let answer = try JSONDecoder().decode(LiveTwitchVideoPlayback.self, from: Data(#"""
      {"video":{"id":"42","title":"Sculpting","owner":{"id":"9","login":"blender_org","displayName":"Blender"},
      "lengthSeconds":3600,"views":10,"previewUrl":"","createdAt":"","type":"archive"},
      "hlsUrl":"/live/hls/master.m3u8?c=42&s=x&t=vod","audioUrl":"/live/hls/master.m3u8?a=1&c=42&t=vod"}
      """#.utf8))
    let stream = try LiveTwitchPlayback.stream(
      video: answer, chapters: [LiveTwitchChapter(start: 600, title: "Art")], origin: URL(string: "https://tv.example.test/api")
    )

    XCTAssertEqual(stream.twitchMedia?.url.absoluteString, "https://tv.example.test/live/hls/master.m3u8?c=42&s=x&t=vod")
    XCTAssertEqual(stream.twitchMedia?.audioURL?.absoluteString, "https://tv.example.test/live/hls/master.m3u8?a=1&c=42&t=vod")
    XCTAssertEqual(stream.duration, 3600)
    XCTAssertFalse(stream.isLive)
    XCTAssertEqual(stream.chapters.map(\.startTimeSeconds), [600])
    XCTAssertEqual(stream.uploaderURL, "https://www.twitch.tv/blender_org")
  }

  func testAnOfflineChannelAndARestrictedVideoSayWhy() throws {
    let offline = try JSONDecoder().decode(LiveTwitchLive.self, from: Data(#"""
      {"channel":{"id":"9","login":"blender_org","displayName":"Blender"},"hlsUrl":"/live/hls/master.m3u8"}
      """#.utf8))

    XCTAssertThrowsError(try LiveTwitchPlayback.stream(live: offline, origin: nil)) { error in
      XCTAssertEqual(error as? LiveTwitchPlaybackError, .offline)
    }
    XCTAssertEqual(LiveTwitchPlaybackError.translating(NetworkError.statusCode(403, nil)) as? LiveTwitchPlaybackError, .restricted)
  }
}

final class LiveTwitchArchiveTimeTests: XCTestCase {
  func testTheRecordingMomentSitsFifteenSecondsBeforeTheLive() throws {
    let now = try XCTUnwrap(LiveTwitchFormat.date("2026-11-17T20:00:00Z"))
    XCTAssertEqual(LiveTwitchArchiveTime.position(startedAt: "2026-11-17T19:00:00Z", now: now), 3_585)
    XCTAssertEqual(LiveTwitchArchiveTime.position(startedAt: "2026-11-17T19:59:55Z", now: now), 0)
    XCTAssertNil(LiveTwitchArchiveTime.position(startedAt: "", now: now))
  }

  func testARewindCloseToTheLiveEdgeStaysOnTheLive() {
    XCTAssertNil(LiveTwitchArchiveTime.rewindTarget(3_580, range: 3_600))
    XCTAssertEqual(LiveTwitchArchiveTime.rewindTarget(3_000.4, range: 3_600), 3_000)
    XCTAssertNil(LiveTwitchArchiveTime.rewindTarget(10, range: 0))
  }
}
