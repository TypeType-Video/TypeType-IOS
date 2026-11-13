import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveLinkedAccountsViewModelTests: XCTestCase {
  func testYouTubeCodeLoginPollsUntilConnectedAndSlowsDownWhenAsked() async {
    let service = FakeLinkedAccounts(youtubePolls: [.pending, .slowDown, .connected])
    let pauses = PauseRecorder()
    let model = LiveLinkedAccountsViewModel(youtube: FakeYouTube(), service: service, pause: pauses.pause)

    model.startYouTube()
    await waitUntil { model.youtubeConnected == true }

    XCTAssertNil(model.youtubeLogin)
    XCTAssertEqual(pauses.durations, [.seconds(5), .seconds(5), .seconds(10)])
  }

  func testBiliBiliQRLoginFollowsTheScanAndEndsOnExpiry() async {
    let service = FakeLinkedAccounts(qrPolls: [.waiting, .scanned, .expired])
    let model = LiveLinkedAccountsViewModel(youtube: FakeYouTube(), service: service, pause: PauseRecorder().pause)

    model.startBiliBili()
    await waitUntil { model.biliBiliError != nil }

    XCTAssertNil(model.biliBiliQR)
    XCTAssertEqual(model.biliBiliError, String(localized: "The QR code expired. Show a new one."))
    XCTAssertEqual(service.polledKeys, ["key", "key", "key"])
  }

  func testBiliBiliConfirmationLinksTheAccount() async {
    let service = FakeLinkedAccounts(qrPolls: [.scanned, .confirmed])
    let model = LiveLinkedAccountsViewModel(youtube: FakeYouTube(), service: service, pause: PauseRecorder().pause)

    model.startBiliBili()
    await waitUntil { model.biliBiliState == .connected }

    XCTAssertFalse(model.biliBiliScanned)
    XCTAssertNil(model.biliBiliError)
  }

  private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<200 where !condition() {
      try? await Task.sleep(for: .milliseconds(5))
    }
  }
}

private final class PauseRecorder {
  var durations: [Duration] = []

  func pause(_ duration: Duration) async throws {
    durations.append(duration)
  }
}

private struct FakeYouTube: LiveYouTubeSessionServiceProtocol {
  func status() async throws -> LiveYouTubeSessionStatus { throw NetworkError.transport }
  func startBrowser() async throws -> LiveYouTubeBrowserSession { throw NetworkError.transport }
  func cancelBrowser(sessionID: String) async throws {}
  func disconnect() async throws {}
}

private final class FakeLinkedAccounts: LiveLinkedAccountsServiceProtocol {
  var youtubePolls: [LiveYouTubeDevicePoll]
  var qrPolls: [LiveBiliBiliQRPoll]
  var polledKeys: [String] = []

  init(youtubePolls: [LiveYouTubeDevicePoll] = [], qrPolls: [LiveBiliBiliQRPoll] = []) {
    self.youtubePolls = youtubePolls
    self.qrPolls = qrPolls
  }

  func startYouTubeLogin() async throws -> LiveYouTubeDeviceLogin {
    LiveYouTubeDeviceLogin(userCode: "ABC-DEF", verificationURL: "https://www.google.com/device", interval: .seconds(5))
  }

  func pollYouTubeLogin() async throws -> LiveYouTubeDevicePoll { youtubePolls.removeFirst() }
  func cancelYouTubeLogin() async throws {}
  func biliBiliState() async throws -> LiveBiliBiliSessionState { .disconnected }

  func startBiliBiliLogin() async throws -> LiveBiliBiliQRLogin {
    try JSONDecoder().decode(LiveBiliBiliQRLogin.self, from: Data(#"{"qrUrl":"https://passport.bilibili.com/x","qrcodeKey":"key"}"#.utf8))
  }

  func pollBiliBiliLogin(key: String) async throws -> LiveBiliBiliQRPoll {
    polledKeys.append(key)
    return qrPolls.removeFirst()
  }

  func disconnectBiliBili() async throws {}
}
