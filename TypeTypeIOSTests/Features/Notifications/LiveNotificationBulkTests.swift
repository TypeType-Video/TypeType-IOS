import XCTest

@testable import TypeTypeIOS

@MainActor
final class LiveNotificationBulkTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testTurningAllOnHasNoChannelLimit() async {
    let preferences = (0..<300).map {
      LiveChannelNotificationPreference(channelURL: "https://youtube.test/channel/\($0)", enabled: false, updatedAt: 1)
    }
    let viewModel = LiveNotificationSettingsViewModel(service: PushServiceStub(preferences: preferences))
    await viewModel.reload()

    await viewModel.setAllEnabled(true)

    XCTAssertEqual(viewModel.toast, .turnedOn(300))
    XCTAssertTrue(viewModel.preferences.allSatisfy(\.enabled))
  }

  func testMessagesUseSingularAndPlural() {
    XCTAssertEqual(LiveNotificationTexts.message(for: .turnedOff(1)), "1 channel turned off.")
    XCTAssertEqual(LiveNotificationTexts.message(for: .turnedOn(3)), "3 channels turned on.")
  }

  func testBulkCallIsRetriedAfterABusyServer() async throws {
    var calls = 0
    URLProtocolStub.register { request in
      calls += 1
      let status = calls == 1 ? 503 : 200
      let body = status == 200
        ? Data(#"[{"channelUrl":"https://youtube.test/channel/1","enabled":true,"updatedAt":2}]"#.utf8)
        : Data()
      let response = try XCTUnwrap(
        HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: status, httpVersion: nil, headerFields: nil)
      )
      return (response, body)
    }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let service = LivePushNotificationsService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: { URL(string: "https://example.test/api") },
        accessTokenProvider: { "token" },
        session: URLSession(configuration: configuration)
      ),
      pacing: .instant
    )

    let updated = try await service.setChannelPreferences(enabled: true, channelURLs: ["https://youtube.test/channel/1"])

    XCTAssertEqual(calls, 2)
    XCTAssertEqual(updated.first?.enabled, true)
  }
}

private final class PushServiceStub: LivePushNotificationsServiceProtocol {
  var preferences: [LiveChannelNotificationPreference]

  init(preferences: [LiveChannelNotificationPreference]) {
    self.preferences = preferences
  }

  func channelPreferences() async throws -> [LiveChannelNotificationPreference] {
    preferences
  }

  func setChannelPreference(channelURL: String, enabled: Bool) async throws -> LiveChannelNotificationPreference {
    LiveChannelNotificationPreference(channelURL: channelURL, enabled: enabled, updatedAt: 2)
  }

  func setChannelPreferences(enabled: Bool, channelURLs: [String]) async throws -> [LiveChannelNotificationPreference] {
    channelURLs.map { LiveChannelNotificationPreference(channelURL: $0, enabled: enabled, updatedAt: 2) }
  }
}
