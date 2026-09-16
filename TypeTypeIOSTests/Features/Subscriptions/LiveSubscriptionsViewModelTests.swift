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

  func testGroupLifecycleKeepsLocalStateCoherent() async throws {
    let service = SubscriptionsStub(
      pages: [
        LiveSubscriptionFeedPage(
          videos: [],
          nextPage: nil
        ),
        LiveSubscriptionFeedPage(
          videos: [],
          nextPage: nil
        ),
      ]
    )
    let viewModel = LiveSubscriptionsViewModel(service: service)
    await viewModel.reload()

    await viewModel.createGroup(named: "  Music  ")
    XCTAssertEqual(viewModel.groups.map(\.name), ["Music"])

    let group = try XCTUnwrap(viewModel.groups.first)
    await viewModel.renameGroup(group, to: "Gaming")
    XCTAssertEqual(viewModel.groups.first?.name, "Gaming")

    await viewModel.selectFilter(.group(id: group.id, name: "Gaming"))
    await viewModel.toggleGroupMembership(
      viewModel.channels[0],
      in: group
    )
    XCTAssertEqual(
      viewModel.groupIDs(for: viewModel.channels[0].channelURL),
      [group.id]
    )
    XCTAssertEqual(
      service.memberships.first?.groupIDs,
      [group.id]
    )
    XCTAssertEqual(service.renamedName, "Gaming")
    XCTAssertTrue(service.addedURLs.contains(viewModel.channels[0].channelURL))

    await viewModel.deleteGroup(group)
    XCTAssertTrue(viewModel.groups.isEmpty)
    XCTAssertTrue(
      viewModel.memberships.allSatisfy { $0.groupIDs.isEmpty }
    )
    XCTAssertEqual(viewModel.filter, .all)
  }
}

private final class SubscriptionsStub: LiveSubscriptionsServiceProtocol {
  var pages: [LiveSubscriptionFeedPage]
  private(set) var cursors: [String?] = []
  private(set) var groups: [LiveSubscriptionGroup] = []
  private(set) var memberships: [
    LiveSubscriptionGroupMembership
  ] = []
  private(set) var renamedName: String?
  private(set) var addedURLs: [String] = []
  private(set) var removedURLs: [String] = []

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
    if pages.isEmpty {
      return LiveSubscriptionFeedPage(
        videos: [],
        nextPage: nil
      )
    }
    return pages.removeFirst()
  }

  func groups() async throws -> [LiveSubscriptionGroup] {
    groups
  }

  func memberships() async throws -> [
    LiveSubscriptionGroupMembership
  ] {
    memberships
  }

  func createGroup(name: String) async throws -> LiveSubscriptionGroup {
    let group = LiveSubscriptionGroup(
      id: UUID().uuidString,
      name: name,
      channelCount: 0,
      createdAt: 0,
      updatedAt: 0
    )
    groups.append(group)
    return group
  }

  func renameGroup(id: String, name: String) async throws {
    renamedName = name
    if let index = groups.firstIndex(where: { $0.id == id }) {
      groups[index] = LiveSubscriptionGroup(
        id: id,
        name: name,
        channelCount: groups[index].channelCount,
        createdAt: groups[index].createdAt,
        updatedAt: 2
      )
    }
  }

  func deleteGroup(id: String) async throws {
    groups.removeAll { $0.id == id }
    memberships.removeAll { $0.groupIDs.contains(id) }
  }

  func addChannels(
    _ channelURLs: [String],
    toGroup id: String
  ) async throws {
    addedURLs.append(contentsOf: channelURLs)
    for channelURL in channelURLs {
      if let index = memberships.firstIndex(
        where: { $0.channelURL == channelURL }
      ) {
        memberships[index].groupIDs.append(id)
      } else {
        memberships.append(
          LiveSubscriptionGroupMembership(
            channelURL: channelURL,
            name: "TypeType",
            avatarURL: "",
            subscribedAt: 2,
            groupIDs: [id]
          )
        )
      }
    }
  }

  func removeChannel(
    _ channelURL: String,
    fromGroup id: String
  ) async throws {
    removedURLs.append(channelURL)
    guard let index = memberships.firstIndex(
      where: { $0.channelURL == channelURL }
    ) else {
      return
    }
    memberships[index].groupIDs.removeAll { $0 == id }
    if memberships[index].groupIDs.isEmpty {
      memberships.remove(at: index)
    }
  }

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
