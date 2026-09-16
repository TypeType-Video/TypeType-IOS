import Foundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveNotificationSettingsViewModelTests: XCTestCase {
  func testPrepareLoadsAndSortsChannelPreferences() async throws {
    let service = NotificationSettingsServiceStub(preferences: [
      Self.preference(url: "https://example.test/c/zeta", enabled: true),
      Self.preference(url: "https://example.test/c/alpha", enabled: false),
    ])
    let viewModel = LiveNotificationSettingsViewModel(service: service)

    await viewModel.prepare()

    XCTAssertEqual(service.loadCount, 1)
    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(
      viewModel.sortedPreferences.map(\.channelURL),
      [
        "https://example.test/c/alpha",
        "https://example.test/c/zeta",
      ]
    )
  }

  func testToggleSavesUpdatedPreference() async throws {
    let original = Self.preference(
      url: "https://example.test/c/alpha",
      enabled: false
    )
    let service = NotificationSettingsServiceStub(preferences: [original])
    let viewModel = LiveNotificationSettingsViewModel(service: service)
    await viewModel.prepare()

    await viewModel.setEnabled(true, for: original)

    XCTAssertEqual(service.updatedURLs, ["https://example.test/c/alpha"])
    XCTAssertTrue(service.updatedEnabled)
    XCTAssertTrue(viewModel.sortedPreferences[0].enabled)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testToggleFailureRevertsOptimisticState() async throws {
    let original = Self.preference(
      url: "https://example.test/c/alpha",
      enabled: false
    )
    let service = NotificationSettingsServiceStub(
      preferences: [original],
      updateError: NetworkError.transport
    )
    let viewModel = LiveNotificationSettingsViewModel(service: service)
    await viewModel.prepare()

    await viewModel.setEnabled(true, for: original)

    XCTAssertFalse(viewModel.sortedPreferences[0].enabled)
    XCTAssertEqual(viewModel.errorMessage, "Network transport failed.")
  }

  private static func preference(
    url: String,
    enabled: Bool
  ) -> LiveChannelNotificationPreference {
    LiveChannelNotificationPreference(
      channelURL: url,
      enabled: enabled,
      updatedAt: 10
    )
  }
}

private final class NotificationSettingsServiceStub: LivePushNotificationsServiceProtocol {
  private let lock = NSLock()
  private var storedPreferences: [LiveChannelNotificationPreference]
  private let updateError: Error?
  private(set) var loadCount = 0
  private(set) var updatedURLs: [String] = []
  private(set) var updatedEnabled = false

  init(
    preferences: [LiveChannelNotificationPreference],
    updateError: Error? = nil
  ) {
    storedPreferences = preferences
    self.updateError = updateError
  }

  func channelPreferences() async throws -> [LiveChannelNotificationPreference] {
    lock.withLock {
      loadCount += 1
    }
    return storedPreferences
  }

  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference {
    lock.withLock {
      updatedURLs.append(channelURL)
      updatedEnabled = enabled
    }
    if let updateError {
      throw updateError
    }

    let preference = LiveChannelNotificationPreference(
      channelURL: channelURL,
      enabled: enabled,
      updatedAt: 20
    )
    lock.withLock {
      if let index = storedPreferences.firstIndex(where: {
        $0.channelURL == channelURL
      }) {
        storedPreferences[index] = preference
      }
    }
    return preference
  }
}
