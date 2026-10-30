import XCTest

@testable import TypeTypeIOS

@MainActor
final class LiveNotificationLimitTests: XCTestCase {
  func testLimitIsOnlyMentionedNearTheEnd() async {
    let viewModel = await loaded(enabled: 50, total: 60)
    XCTAssertEqual(viewModel.limit, .comfortable)
    XCTAssertNil(LiveNotificationTexts.note(for: viewModel.limit))

    let close = await loaded(enabled: 115, total: 118)
    XCTAssertEqual(close.limit, .close(remaining: 5))

    let full = await loaded(enabled: 120, total: 121)
    XCTAssertEqual(full.limit, .reached)
  }

  func testTurningAllOnStopsAtTheLimitAndSaysHowMany() async {
    let viewModel = await loaded(enabled: 118, total: 123)

    await viewModel.setAllEnabled(true)

    XCTAssertEqual(viewModel.toast, .turnedOn(2, leftOff: 3))
    XCTAssertEqual(viewModel.toast?.isWarning, true)
  }

  func testMessagesUseSingularAndPlural() {
    XCTAssertEqual(LiveNotificationTexts.message(for: .turnedOff(1)), "1 channel turned off.")
    XCTAssertEqual(LiveNotificationTexts.message(for: .turnedOff(3)), "3 channels turned off.")
    XCTAssertFalse(LiveNotificationTexts.message(for: .limitReached).contains("quer"))
  }

  private func loaded(enabled: Int, total: Int) async -> LiveNotificationSettingsViewModel {
    let preferences = (0..<total).map { index in
      LiveChannelNotificationPreference(
        channelURL: "https://youtube.test/channel/\(index)",
        enabled: index < enabled,
        updatedAt: 1
      )
    }
    let viewModel = LiveNotificationSettingsViewModel(service: PushServiceStub(preferences: preferences))
    await viewModel.reload()
    return viewModel
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
