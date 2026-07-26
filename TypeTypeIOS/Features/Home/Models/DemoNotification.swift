import Foundation

struct DemoNotification: Identifiable, Hashable {
  let id: String
  let title: String
  let message: String
  let timestamp: String
  let artwork: DemoArtwork
  let video: DemoVideo?
  var isRead: Bool
}

enum DemoNotificationCatalog {
  static let initial = [
    DemoNotification(
      id: "blender-upload",
      title: "Blender Open Movies published a video",
      message: "Big Buck Bunny is available in pristine open-source quality.",
      timestamp: "12 min ago",
      artwork: .television,
      video: DemoMockCatalog.continueWatching[0],
      isRead: false
    ),
    DemoNotification(
      id: "pipepipe-sabr",
      title: "New from PipePipe",
      message: "A practical breakdown of resilient SABR playback.",
      timestamp: "2 hours ago",
      artwork: .pipePipe,
      video: DemoMockCatalog.recommendations[1],
      isRead: false
    ),
    DemoNotification(
      id: "download-ready",
      title: "Download ready",
      message: "Open movie night is now available offline.",
      timestamp: "Yesterday",
      artwork: .bird,
      video: nil,
      isRead: true
    ),
    DemoNotification(
      id: "typetype-design",
      title: "TypeType published a design journal",
      message: "A calmer native navigation system for iPhone and iPad.",
      timestamp: "2 days ago",
      artwork: .typeType,
      video: DemoMockCatalog.recommendations[0],
      isRead: true
    ),
    DemoNotification(
      id: "open-media",
      title: "Open Media has a new upload",
      message: "Discovery without tracking, explained with practical examples.",
      timestamp: "3 days ago",
      artwork: .bird,
      video: DemoMockCatalog.recommendations[4],
      isRead: true
    ),
    DemoNotification(
      id: "self-hosted",
      title: "Self-Hosted Lab is live",
      message: "A private video home from an empty server.",
      timestamp: "Last week",
      artwork: .dog,
      video: DemoMockCatalog.recommendations[2],
      isRead: true
    ),
  ]
}
