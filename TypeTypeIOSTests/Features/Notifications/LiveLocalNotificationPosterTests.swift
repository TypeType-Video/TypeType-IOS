import UserNotifications
import XCTest
@testable import TypeTypeIOS

final class LiveLocalNotificationPosterTests: XCTestCase {
  func testOnlyUnreadItemsNewerThanTheMarkArePostedOldestFirst() throws {
    let items = try [
      notification(id: "old", createdAt: 100, read: false),
      notification(id: "read", createdAt: 300, read: true),
      notification(id: "newer", createdAt: 400, read: false),
      notification(id: "new", createdAt: 250, read: false),
    ]

    let fresh = LiveLocalNotificationPoster.fresh(items, after: 200)

    XCTAssertEqual(fresh.map(\.id), ["new", "newer"])
  }

  func testABurstIsCappedToTheNewest() throws {
    let items = try (1...9).map { try notification(id: "n\($0)", createdAt: Int64($0), read: false) }

    let fresh = LiveLocalNotificationPoster.fresh(items, after: 0)

    XCTAssertEqual(fresh.map(\.id), ["n5", "n6", "n7", "n8", "n9"])
  }

  func testTheRequestOpensTheVideoThroughTheTypeTypeLink() throws {
    let item = try notification(id: "n1", createdAt: 1, read: false)

    let request = LiveLocalNotificationPoster.request(for: item)

    XCTAssertEqual(request.identifier, "n1")
    XCTAssertEqual(request.content.title, "TypeType")
    XCTAssertEqual(request.content.userInfo["url"] as? String, item.deepLinkURL?.absoluteString)
  }

  private func notification(id: String, createdAt: Int64, read: Bool) throws -> LiveNotification {
    let video = try JSONSerialization.jsonObject(with: JSONEncoder().encode(LiveVideoItemFixture.make()))
    let payload: [String: Any] = [
      "id": id, "read": read, "type": "subscription_new_video", "title": "TypeType uploaded a new video",
      "createdAt": createdAt, "publishedAt": createdAt, "channelUrl": "https://www.youtube.com/@typetype",
      "channelName": "TypeType", "channelAvatarUrl": "https://example.test/avatar.jpg", "video": video,
    ]
    return try JSONDecoder().decode(LiveNotification.self, from: JSONSerialization.data(withJSONObject: payload))
  }
}
