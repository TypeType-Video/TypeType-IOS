import XCTest
@testable import TypeTypeIOS

final class LiveTwitchAccountServiceTests: XCTestCase {
  func testExplainsARefusedMessageAndASpentFreeVote() async {
    let refused = LiveTwitchAccountService(apiClient: FailingClient(error: .statusCode(400, "chat_rejected", code: "msg_slowmode")))
    let failed = LiveTwitchAccountService(apiClient: FailingClient(error: .statusCode(502, "upstream", code: nil)))
    let spent = LiveTwitchAccountService(apiClient: FailingClient(error: .statusCode(400, "vote failed", code: "TOKENS_REQUIRED")))

    let refusal: LiveTwitchChatSendResult = await refused.send("hi", login: "blender_org")
    let failure: LiveTwitchChatSendResult = await failed.send("hi", login: "blender_org")
    let vote: LiveTwitchVoteResult = await spent.vote(pollID: "p", choiceID: "c")
    XCTAssertEqual(refusal, LiveTwitchChatSendResult.rejected(reason: "msg_slowmode"))
    XCTAssertEqual(failure, LiveTwitchChatSendResult.failed)
    XCTAssertEqual(vote, LiveTwitchVoteResult.freeVoteSpent)
  }
}

@MainActor
final class LiveTwitchLinkViewModelTests: XCTestCase {
  func testShowsTheCodeSlowsDownWhenAskedAndEndsLinked() async throws {
    let service = LinkService(polls: [.pending, .slowDown, .ok])
    var pauses: [Duration] = []
    let model = LiveTwitchLinkViewModel(service: service) { pauses.append($0) }

    model.start()
    for _ in 0..<50 where !model.isLinked { await Task.yield() }

    XCTAssertTrue(model.isLinked)
    XCTAssertNil(model.device)
    XCTAssertEqual(model.status?.name, "Viewer")
    XCTAssertEqual(pauses, [.seconds(5), .seconds(5), .seconds(10)])
  }

  func testSubscriptionLabelsMatchTheWeb() {
    let long = LiveTwitchSubscription(tier: "2000", prime: false, months: 14, streak: 3)
    let prime = LiveTwitchSubscription(tier: "1000", prime: true, months: 1, streak: 1)
    XCTAssertEqual(LiveTwitchChatText.subscription(long), "Subscribed · 14 months")
    XCTAssertEqual(LiveTwitchChatText.subscriptionDetails(long), ["3-month streak", "Tier 2"])
    XCTAssertEqual(LiveTwitchChatText.subscription(prime), "Subscribed · 1 month")
    XCTAssertEqual(LiveTwitchChatText.subscriptionDetails(prime), ["Prime"])
  }
}

private final class FailingClient: APIClient, @unchecked Sendable {
  let error: NetworkError

  init(error: NetworkError) {
    self.error = error
  }

  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T { throw error }
  func request(_ endpoint: APIEndpoint) async throws { throw error }
  func requestData(_ endpoint: APIEndpoint) async throws -> Data { throw error }
}

private final class LinkService: LiveTwitchAccountServiceProtocol, @unchecked Sendable {
  private var polls: [LiveTwitchDevicePoll.Status]

  init(polls: [LiveTwitchDevicePoll.Status]) {
    self.polls = polls
  }

  func account() async throws -> LiveTwitchAccountStatus { LiveTwitchAccountStatus(linked: false, login: nil, displayName: nil, avatarURL: nil) }
  func startLink() async throws -> LiveTwitchDeviceCode {
    LiveTwitchDeviceCode(deviceCode: "device", userCode: "ABCD-EFGH", verificationURI: "https://www.twitch.tv/activate", interval: 5, expiresIn: 600)
  }
  func pollLink(deviceCode: String) async throws -> LiveTwitchDevicePoll {
    let status = polls.removeFirst()
    let account = status == .ok ? LiveTwitchAccountStatus(linked: true, login: "viewer", displayName: "Viewer", avatarURL: nil) : nil
    return LiveTwitchDevicePoll(status: status, account: account)
  }
  func unlink() async throws {}
  func followedLive(after: String?) async throws -> LiveTwitchPage<LiveTwitchStream> { throw CancellationError() }
  func followedVideos(after: String?) async throws -> LiveTwitchPage<LiveTwitchVideo> { throw CancellationError() }
  func followedChannels(after: String?) async throws -> LiveTwitchPage<LiveTwitchUser> { throw CancellationError() }
  func follow(login: String) async throws -> LiveTwitchFollowState { throw CancellationError() }
  func setFollow(login: String, following: Bool) async throws -> LiveTwitchFollowState { throw CancellationError() }
  func userEmotes(login: String) async throws -> LiveTwitchUserEmotes { throw CancellationError() }
  func chatAssets(login: String?) async throws -> LiveTwitchChatAssets { .empty }
  func highlights(login: String) async throws -> LiveTwitchChatHighlights { throw CancellationError() }
  func send(_ message: String, login: String) async -> LiveTwitchChatSendResult { .failed }
  func vote(pollID: String, choiceID: String) async -> LiveTwitchVoteResult { .failed }
  func videoComments(id: String, request: LiveTwitchVodChatWindow.Request) async throws -> LiveTwitchPage<LiveTwitchVideoComment> {
    throw CancellationError()
  }
}
