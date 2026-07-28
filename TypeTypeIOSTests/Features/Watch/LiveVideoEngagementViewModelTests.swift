import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveVideoEngagementViewModelTests: XCTestCase {
  func testSubscriptionStateUsesBackendAndMutatesBackend() async {
    let video = LiveVideoItemFixture.make()
    let service = EngagementSubscriptionsStub(
      values: [
        LiveSubscription(
          channelURL: "\(video.uploaderURL)/",
          name: video.uploaderName,
          avatarURL: video.uploaderAvatarURL,
          subscribedAt: 1
        ),
      ]
    )
    let viewModel = LiveVideoEngagementViewModel(
      video: video,
      allowsSubscription: true,
      service: service
    )

    await viewModel.prepare()
    XCTAssertTrue(viewModel.isSubscribed)

    await viewModel.toggleSubscription()
    XCTAssertFalse(viewModel.isSubscribed)
    XCTAssertEqual(service.unsubscribedURLs, [video.uploaderURL])

    await viewModel.toggleSubscription()
    XCTAssertTrue(viewModel.isSubscribed)
    XCTAssertEqual(service.subscribedURLs, [video.uploaderURL])
  }

  func testGuestDoesNotRequestSubscriptions() async {
    let service = EngagementSubscriptionsStub(values: [])
    let viewModel = LiveVideoEngagementViewModel(
      video: LiveVideoItemFixture.make(),
      allowsSubscription: false,
      service: service
    )

    await viewModel.prepare()
    await viewModel.toggleSubscription()

    XCTAssertFalse(viewModel.canSubscribe)
    XCTAssertEqual(service.loadCount, 0)
    XCTAssertTrue(service.subscribedURLs.isEmpty)
  }
}

private final class EngagementSubscriptionsStub:
  LiveSubscriptionsServiceProtocol {
  let values: [LiveSubscription]
  private(set) var loadCount = 0
  private(set) var subscribedURLs: [String] = []
  private(set) var unsubscribedURLs: [String] = []

  init(values: [LiveSubscription]) {
    self.values = values
  }

  func subscriptions() async throws -> [LiveSubscription] {
    loadCount += 1
    return values
  }

  func feed(
    nextPage: String?
  ) async throws -> LiveSubscriptionFeedPage {
    LiveSubscriptionFeedPage(videos: [], nextPage: nil)
  }

  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription {
    subscribedURLs.append(channelURL)
    return LiveSubscription(
      channelURL: channelURL,
      name: name,
      avatarURL: avatarURL,
      subscribedAt: 1
    )
  }

  func unsubscribe(channelURL: String) async throws {
    unsubscribedURLs.append(channelURL)
  }
}
