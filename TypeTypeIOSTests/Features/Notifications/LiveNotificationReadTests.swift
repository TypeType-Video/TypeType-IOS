import Foundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveNotificationReadTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testServerNotificationDecodesIDReadStateAndDeepLink() throws {
    let notification = try JSONDecoder().decode(
      LiveNotification.self,
      from: Self.notificationData(
        id: "notification-1",
        read: false
      )
    )

    XCTAssertEqual(notification.serverID, "notification-1")
    XCTAssertFalse(notification.read)
    XCTAssertEqual(
      notification.deepLinkURL?.absoluteString,
      "typetype://watch?v=https://www.youtube.com/watch?v%3Dvideo-1"
    )
    guard case let .video(video) = LiveMediaLinkResolver.destination(
      for: try XCTUnwrap(notification.deepLinkURL)
    ) else {
      return XCTFail("A notification deep link should open a video.")
    }
    XCTAssertEqual(video.url, notification.video.url)
  }

  func testMarkReadUsesServerContractAndSynchronizesBadge() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(
        request.url?.path,
        "/api/notifications/notification-1/read"
      )
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer test-token"
      )
      return try Self.response(
        request,
        status: 200,
        body: """
        {"readAt": 123, "unreadCount": 1}
        """
      )
    }

    let service = LiveNotificationsService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: { URL(string: "https://example.test/api") },
        accessTokenProvider: { "test-token" },
        session: Self.makeSession()
      )
    )
    let result = try await service.markRead(notificationID: "notification-1")
    XCTAssertEqual(result.unreadCount, 1)
  }

  func testOpeningNotificationOptimisticallyMarksItRead() async throws {
    let service = NotificationServiceStub(
      page: try Self.page(
        unreadCount: 2,
        items: [
          Self.notificationData(id: "one", read: false),
          Self.notificationData(id: "two", read: false),
        ]
      ),
      unreadCount: 2,
      markReadUnreadCount: 1
    )
    let center = LiveNotificationCenter(service: service)
    let viewModel = LiveNotificationsViewModel(
      service: service,
      notificationCenter: center
    )
    await viewModel.prepare()

    let openedVideo = viewModel.markReadAndOpen(try XCTUnwrap(viewModel.items.first))
    try await Task.sleep(for: .milliseconds(20))

    XCTAssertEqual(openedVideo.id, "video-1")
    XCTAssertEqual(service.markReadIDs, ["one"])
    XCTAssertEqual(viewModel.unreadCount, 1)
    XCTAssertTrue(viewModel.items[0].read)
    XCTAssertFalse(viewModel.items[1].read)
    XCTAssertEqual(center.unreadCount, 1)
  }

  func testFailedSingleReadRevertsOptimisticState() async throws {
    let service = NotificationServiceStub(
      page: try Self.page(
        unreadCount: 2,
        items: [
          Self.notificationData(id: "one", read: false),
          Self.notificationData(id: "two", read: false),
        ]
      ),
      unreadCount: 2,
      markReadUnreadCount: 1,
      markReadError: NetworkError.transport
    )
    let center = LiveNotificationCenter(service: service)
    let viewModel = LiveNotificationsViewModel(
      service: service,
      notificationCenter: center
    )
    await viewModel.prepare()

    _ = viewModel.markReadAndOpen(try XCTUnwrap(viewModel.items.first))
    try await Task.sleep(for: .milliseconds(20))

    XCTAssertEqual(service.markReadIDs, ["one"])
    XCTAssertFalse(viewModel.items[0].read)
    XCTAssertEqual(viewModel.unreadCount, 2)
    XCTAssertEqual(center.unreadCount, 2)
    XCTAssertNotNil(viewModel.errorMessage)
  }

  private static func notificationData(
    id: String,
    read: Bool
  ) throws -> Data {
    let video = LiveVideoItemFixture.make()
    let videoData = try JSONEncoder().encode(video)
    let payload: [String: Any] = [
      "id": id,
      "read": read,
      "type": "subscription_new_video",
      "title": "TypeType uploaded a new video",
      "createdAt": 1_000,
      "publishedAt": 1_000,
      "channelUrl": "https://www.youtube.com/@typetype",
      "channelName": "TypeType",
      "channelAvatarUrl": "https://example.test/avatar.jpg",
      "video": try JSONSerialization.jsonObject(with: videoData),
    ]
    return try JSONSerialization.data(withJSONObject: payload)
  }

  private static func page(
    unreadCount: Int,
    items: [Data]
  ) throws -> LiveNotificationsPage {
    let itemJSON = items.map { String(decoding: $0, as: UTF8.self) }
    return try JSONDecoder().decode(
      LiveNotificationsPage.self,
      from: Data(
        """
        {"items":[\(itemJSON.joined(separator: ","))],"unreadCount":\(unreadCount),"nextpage":null}
        """.utf8
      )
    )
  }

  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    status: Int,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw TestError.missingURL
    }
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: url,
        statusCode: status,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }
}

private final class NotificationServiceStub: LiveNotificationsServiceProtocol {
  private let lock = NSLock()
  private let page: LiveNotificationsPage
  private let unreadCount: Int
  private let markReadUnreadCount: Int
  private let markReadError: Error?
  private(set) var markReadIDs: [String] = []

  init(
    page: LiveNotificationsPage,
    unreadCount: Int,
    markReadUnreadCount: Int,
    markReadError: Error? = nil
  ) {
    self.page = page
    self.unreadCount = unreadCount
    self.markReadUnreadCount = markReadUnreadCount
    self.markReadError = markReadError
  }

  func unreadCount() async throws -> Int {
    unreadCount
  }

  func notifications(
    page: Int,
    limit: Int
  ) async throws -> LiveNotificationsPage {
    self.page
  }

  func markAllRead() async throws -> LiveNotificationsReadResult {
    LiveNotificationsReadResult(readAt: 1, unreadCount: 0)
  }

  func markRead(
    notificationID: String
  ) async throws -> LiveNotificationsReadResult {
    lock.withLock {
      markReadIDs.append(notificationID)
    }
    if let markReadError {
      throw markReadError
    }
    return LiveNotificationsReadResult(
      readAt: 1,
      unreadCount: markReadUnreadCount
    )
  }
}

private enum TestError: Error {
  case missingURL
}
