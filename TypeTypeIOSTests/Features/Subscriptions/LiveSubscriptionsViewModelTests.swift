import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveSubscriptionsViewModelTests: XCTestCase {
  func testInitialLoadIncludesShortsAndDeduplicates() async {
    let video = LiveVideoItemFixture.make()
    let duplicate = LiveVideoItemFixture.make(id: "duplicate")
    let short = LiveVideoItemFixture.make(
      id: "short",
      url: "https://youtube.test/shorts/short",
      isShort: true
    )
    let service = SubscriptionsStub(
      pages: [
        LiveSubscriptionFeedPage(
          videos: [video, duplicate, short],
          nextPage: "next"
        ),
      ]
    )
    let viewModel = LiveSubscriptionsViewModel(service: service)

    await viewModel.reload()

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(
      viewModel.visibleVideos.map(\.id),
      ["video-1", "short"]
    )
    XCTAssertEqual(viewModel.channels.count, 1)
    XCTAssertTrue(viewModel.canLoadMore)
  }

  func testPaginationUsesCursorAndDeduplicates() async {
    let first = LiveVideoItemFixture.make()
    let second = LiveVideoItemFixture.make(
      id: "second",
      url: "https://video.test/second"
    )
    let service = SubscriptionsStub(
      pages: [
        LiveSubscriptionFeedPage(
          videos: [first],
          nextPage: "next"
        ),
        LiveSubscriptionFeedPage(
          videos: [first, second],
          nextPage: nil
        ),
      ]
    )
    let viewModel = LiveSubscriptionsViewModel(service: service)

    await viewModel.reload()
    await viewModel.loadMore()

    XCTAssertEqual(viewModel.videos.map(\.id), ["video-1", "second"])
    XCTAssertEqual(service.cursors, [nil, "next"])
    XCTAssertFalse(viewModel.canLoadMore)
  }
}

private final class SubscriptionsStub: LiveSubscriptionsServiceProtocol {
  var pages: [LiveSubscriptionFeedPage]
  private(set) var cursors: [String?] = []

  init(pages: [LiveSubscriptionFeedPage]) {
    self.pages = pages
  }

  func subscriptions() async throws -> [LiveSubscription] {
    [
      LiveSubscription(
        channelURL: "https://channel.test/1",
        name: "TypeType",
        avatarURL: "",
        subscribedAt: 1
      ),
    ]
  }

  func feed(
    nextPage: String?,
    filter: LiveSubscriptionFilter
  ) async throws -> LiveSubscriptionFeedPage {
    cursors.append(nextPage)
    return pages.removeFirst()
  }

  func groups() async throws -> [LiveSubscriptionGroup] { [] }

  func memberships() async throws -> [
    LiveSubscriptionGroupMembership
  ] { [] }

  func createGroup(name: String) async throws -> LiveSubscriptionGroup {
    LiveSubscriptionGroup(
      id: "group",
      name: name,
      channelCount: 0,
      createdAt: 0,
      updatedAt: 0
    )
  }

  func renameGroup(id: String, name: String) async throws {}
  func deleteGroup(id: String) async throws {}

  func addChannels(
    _ channelURLs: [String],
    toGroup id: String
  ) async throws {}

  func removeChannel(
    _ channelURL: String,
    fromGroup id: String
  ) async throws {}

  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription {
    LiveSubscription(
      channelURL: channelURL,
      name: name,
      avatarURL: avatarURL,
      subscribedAt: 1
    )
  }

  func unsubscribe(channelURL: String) async throws {}
}
