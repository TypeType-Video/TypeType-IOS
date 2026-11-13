import XCTest
@testable import TypeTypeIOS

final class LiveUserErrorTests: XCTestCase {
  func testServerCodesNameTheCause() {
    XCTAssertEqual(kind(503, "provider_access_blocked"), .providerBlocked)
    XCTAssertEqual(kind(503, "token_service_unavailable"), .providerBlocked)
    XCTAssertEqual(kind(429, "rate_limited"), .rateLimited)
    XCTAssertEqual(kind(504, "sabr_upstream_timeout"), .serverSlow)
    XCTAssertEqual(kind(403, "content_blocked"), .contentBlocked)
    XCTAssertEqual(kind(403, "members_only"), .membersOnly)
    XCTAssertEqual(kind(403, "private_content"), .privateContent)
    XCTAssertEqual(kind(403, "age_restricted"), .ageRestricted)
  }

  func testStatusesWithoutACodeStillGetAMeaning() {
    XCTAssertEqual(kind(401, nil), .signInAgain)
    XCTAssertEqual(kind(404, nil), .contentUnavailable)
    XCTAssertEqual(kind(409, nil), .conflict)
    XCTAssertEqual(kind(502, nil), .serverUnavailable)
    XCTAssertEqual(kind(422, nil), .other)
  }

  func testTransportFailuresTellOfflineFromUnreachableAndSlow() {
    XCTAssertEqual(LiveUserError(NetworkError.transport), .instanceUnreachable)
    XCTAssertEqual(LiveUserError(NetworkError.transport, online: false), .offline)
    XCTAssertEqual(LiveUserError(URLError(.notConnectedToInternet)), .offline)
    XCTAssertEqual(LiveUserError(URLError(.timedOut)), .serverSlow)
    XCTAssertEqual(LiveUserError(URLError(.cannotConnectToHost)), .instanceUnreachable)
  }

  @MainActor
  func testAProviderBlockIsNeverRetried() {
    let blocked = NetworkError.statusCode(503, "blocked", code: "provider_access_blocked")
    XCTAssertTrue(blocked.isProviderBlock)
    XCTAssertNil(LivePlaybackService.sabrRetryDelayMS(for: blocked, failureCount: 1))
    XCTAssertFalse(LivePlayerController.isTransientStartupFailure(blocked))
    XCTAssertNotNil(LivePlaybackService.sabrRetryDelayMS(for: NetworkError.statusCode(503, nil), failureCount: 1))
  }

  func testMessagesPreferTheNamedCauseThenTheServerText() {
    XCTAssertEqual(
      NetworkError.statusCode(503, "Use a VPN", code: "provider_access_blocked").errorDescription,
      LiveUserError.providerBlocked.message
    )
    XCTAssertEqual(NetworkError.statusCode(422, "Only in Japan").errorDescription, "Only in Japan")
  }

  private func kind(_ status: Int, _ code: String?) -> LiveUserError {
    LiveUserError(NetworkError.statusCode(status, nil, code: code))
  }
}
