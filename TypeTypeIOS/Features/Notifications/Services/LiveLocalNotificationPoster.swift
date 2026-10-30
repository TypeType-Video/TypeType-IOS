import Foundation
import UserNotifications

// The server sends no Apple push: the background refresh turns new unread notifications into local ones.
struct LiveLocalNotificationPoster {
  static let perRun = 5
  let center: UNUserNotificationCenter
  let defaults: UserDefaults

  func post(_ items: [LiveNotification], unreadCount: Int, scope: String) async {
    let key = "live.notifications.posted.\(scope)"
    let newest = items.map(\.createdAt).max() ?? 0
    // A first run only takes the mark: the unread backlog would otherwise arrive as a burst.
    guard let mark = (defaults.object(forKey: key) as? NSNumber)?.int64Value else {
      defaults.set(NSNumber(value: newest), forKey: key)
      return
    }
    defaults.set(NSNumber(value: max(mark, newest)), forKey: key)
    let status = await center.notificationSettings().authorizationStatus
    guard status == .authorized || status == .provisional else { return }
    do {
      for item in Self.fresh(items, after: mark) {
        try await center.add(Self.request(for: item))
      }
      try await center.setBadgeCount(unreadCount)
    } catch {
      AppLogger.app.failure("Posting local notifications", error)
    }
  }

  static func fresh(_ items: [LiveNotification], after mark: Int64) -> [LiveNotification] {
    let unseen = items.filter { !$0.read && $0.createdAt > mark }.sorted { $0.createdAt < $1.createdAt }
    return Array(unseen.suffix(perRun))
  }

  static func request(for item: LiveNotification) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = item.channelName
    content.body = item.video.title.isEmpty ? item.title : item.video.title
    content.threadIdentifier = item.channelURL
    content.sound = .default
    if let url = item.deepLinkURL {
      content.userInfo = ["url": url.absoluteString]
    }
    return UNNotificationRequest(identifier: item.id, content: content, trigger: nil)
  }
}
