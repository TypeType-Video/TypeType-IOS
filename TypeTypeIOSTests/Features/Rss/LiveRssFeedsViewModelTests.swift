import Foundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveRssFeedsViewModelTests: XCTestCase {
  func testPrepareLoadsFeedsAndSubscriptions() async {
    let service = RssFeedsServiceStub()
    let viewModel = LiveRssFeedsViewModel(
      feedService: service,
      subscriptionsService: service
    )

    await viewModel.prepare()

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(viewModel.feeds.count, 1)
    XCTAssertEqual(viewModel.subscriptions.count, 2)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testSaveRequiresChannelSelectionInChannelScope() async {
    let service = RssFeedsServiceStub()
    let viewModel = LiveRssFeedsViewModel(
      feedService: service,
      subscriptionsService: service
    )
    await viewModel.prepare()
    viewModel.startCreate()
    viewModel.draftName = "Selected"
    viewModel.draftIncludesChannels = true

    await viewModel.save()

    XCTAssertEqual(service.createCount, 0)
    XCTAssertEqual(
      viewModel.errorMessage,
      "Select at least one subscribed channel."
    )
  }

  func testCreateUsesDraftAndReloads() async {
    let service = RssFeedsServiceStub()
    let viewModel = LiveRssFeedsViewModel(
      feedService: service,
      subscriptionsService: service
    )
    await viewModel.prepare()
    viewModel.startCreate()
    viewModel.draftName = "New feed"

    await viewModel.save()

    XCTAssertEqual(service.createCount, 1)
    XCTAssertEqual(viewModel.feeds.count, 2)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testFailedToggleDoesNotLoseFeed() async throws {
    let service = RssFeedsServiceStub()
    service.enabledError = NetworkError.transport
    let viewModel = LiveRssFeedsViewModel(
      feedService: service,
      subscriptionsService: service
    )
    await viewModel.prepare()
    let feed = try XCTUnwrap(viewModel.feeds.first)

    await viewModel.setEnabled(false, for: feed)

    XCTAssertEqual(viewModel.feeds.first?.enabled, true)
    XCTAssertEqual(viewModel.errorMessage, LiveUserError.instanceUnreachable.message)
  }
}

private final class RssFeedsServiceStub: LiveRssFeedServiceProtocol, LiveSubscriptionsServiceProtocol {
  var enabledError: Error?
  private(set) var createCount = 0

  private let existingFeed = LiveRssFeed(
    id: "feed-1",
    name: "All subscriptions",
    scope: "all",
    channelURLs: [],
    serviceIDs: [0, 5, 6],
    includeVideos: true,
    includeShorts: true,
    includeLive: true,
    includeUpcoming: true,
    enabled: true,
    createdAt: 1,
    updatedAt: 1,
    lastUsedAt: nil
  )

  func feeds() async throws -> [LiveRssFeed] {
    [existingFeed]
  }

  func create(draft: LiveRssFeedDraft) async throws -> LiveRssFeedSecret {
    createCount += 1
    let feed = LiveRssFeed(
      id: "created",
      name: draft.name,
      scope: draft.scope,
      channelURLs: draft.channelURLs,
      serviceIDs: draft.serviceIDs,
      includeVideos: draft.includeVideos,
      includeShorts: draft.includeShorts,
      includeLive: draft.includeLive,
      includeUpcoming: draft.includeUpcoming,
      enabled: true,
      createdAt: 2,
      updatedAt: 2,
      lastUsedAt: nil
    )
    return LiveRssFeedSecret(
      feed: feed,
      feedURL: "https://example.test/rss/created.xml?token=secret"
    )
  }

  func update(
    id: String,
    draft: LiveRssFeedDraft
  ) async throws -> LiveRssFeed {
    throw NetworkError.invalidResponse
  }

  func setEnabled(
    id: String,
    enabled: Bool
  ) async throws -> LiveRssFeed {
    if let enabledError {
      throw enabledError
    }
    return LiveRssFeed(
      id: id,
      name: existingFeed.name,
      scope: existingFeed.scope,
      channelURLs: existingFeed.channelURLs,
      serviceIDs: existingFeed.serviceIDs,
      includeVideos: true,
      includeShorts: true,
      includeLive: true,
      includeUpcoming: true,
      enabled: enabled,
      createdAt: 1,
      updatedAt: 2,
      lastUsedAt: nil
    )
  }

  func regenerate(id: String) async throws -> LiveRssFeedSecret {
    throw NetworkError.invalidResponse
  }

  func delete(id: String) async throws {
    throw NetworkError.invalidResponse
  }

  func subscriptions() async throws -> [LiveSubscription] {
    [
      LiveSubscription(
        channelURL: "https://youtube.test/channel/one",
        name: "One",
        avatarURL: "",
        subscribedAt: 1
      ),
      LiveSubscription(
        channelURL: "https://youtube.test/channel/two",
        name: "Two",
        avatarURL: "",
        subscribedAt: 2
      ),
    ]
  }

  func feed(
    nextPage: String?,
    filter: LiveSubscriptionFilter
  ) async throws -> LiveSubscriptionFeedPage {
    throw NetworkError.invalidResponse
  }

  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription {
    throw NetworkError.invalidResponse
  }

  func unsubscribe(channelURL: String) async throws {
    throw NetworkError.invalidResponse
  }

  func groups() async throws -> [LiveSubscriptionGroup] {
    []
  }

  func memberships() async throws -> [LiveSubscriptionGroupMembership] {
    []
  }

  func createGroup(name: String) async throws -> LiveSubscriptionGroup {
    throw NetworkError.invalidResponse
  }

  func renameGroup(id: String, name: String) async throws {
    throw NetworkError.invalidResponse
  }

  func deleteGroup(id: String) async throws {
    throw NetworkError.invalidResponse
  }

  func addChannels(
    _ channelURLs: [String],
    toGroup id: String
  ) async throws {
    throw NetworkError.invalidResponse
  }

  func removeChannel(
    _ channelURL: String,
    fromGroup id: String
  ) async throws {
    throw NetworkError.invalidResponse
  }
}
