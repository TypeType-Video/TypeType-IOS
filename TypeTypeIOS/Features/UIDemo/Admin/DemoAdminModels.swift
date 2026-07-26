import Foundation

struct DemoAdminSettings {
  var allowsRegistration = true
  var allowsGuests = true
  var tracksActiveSessions = true
  var allowsLocalLogin = true
  var redirectsToOIDC = false
  var allowsYouTubeRemoteLogin = true
}

struct DemoAdminUser: Identifiable, Hashable {
  let id: String
  var name: String
  var email: String
  var role: String
  var isSuspended: Bool
  var isVerified: Bool

  static let initial = [
    DemoAdminUser(
      id: "user-typetype",
      name: "TypeType",
      email: "demo@typetype.video",
      role: "admin",
      isSuspended: false,
      isVerified: true
    ),
    DemoAdminUser(
      id: "user-moderator",
      name: "Open Media",
      email: "moderator@example.test",
      role: "moderator",
      isSuspended: false,
      isVerified: true
    ),
    DemoAdminUser(
      id: "user-viewer",
      name: "Bunny Viewer",
      email: "viewer@example.test",
      role: "user",
      isSuspended: false,
      isVerified: false
    ),
    DemoAdminUser(
      id: "user-paused",
      name: "Paused Account",
      email: "paused@example.test",
      role: "user",
      isSuspended: true,
      isVerified: false
    ),
  ]
}

struct DemoAdminSession: Identifiable {
  let id: String
  let userID: String
  let device: String
  let lastSeen: String
  let video: DemoVideo?
  let position: Double

  static let initial = [
    DemoAdminSession(
      id: "session-iphone",
      userID: "user-typetype",
      device: "iPhone 17 · iOS",
      lastSeen: "Active now",
      video: DemoMockCatalog.continueWatching[0],
      position: 0.42
    ),
    DemoAdminSession(
      id: "session-browser",
      userID: "user-moderator",
      device: "Zen Browser · Linux",
      lastSeen: "2 minutes ago",
      video: DemoMockCatalog.recommendations[0],
      position: 0.18
    ),
    DemoAdminSession(
      id: "session-ipad",
      userID: "user-viewer",
      device: "iPad · iPadOS",
      lastSeen: "8 minutes ago",
      video: nil,
      position: 0
    ),
  ]
}

struct DemoAdminIssue: Identifiable, Hashable {
  let id: String
  var title: String
  var category: String
  var status: String
  let reporter: String
  let detail: String
  let diagnostics: String
  var githubIssue: String?

  static let initial = [
    DemoAdminIssue(
      id: "BUG-104",
      title: "SABR seek recovers slowly",
      category: "Playback",
      status: "Open",
      reporter: "viewer@example.test",
      detail: "Seeking after a codec change briefly shows the loading indicator.",
      diagnostics: "iOS 26.5 · iPhone 17 · SABR · AV1",
      githubIssue: nil
    ),
    DemoAdminIssue(
      id: "BUG-103",
      title: "Playlist order feedback",
      category: "Interface",
      status: "Triaged",
      reporter: "moderator@example.test",
      detail: "Manual playlist ordering should expose clearer controls.",
      diagnostics: "Zen Browser · Linux · 390x844 viewport",
      githubIssue: "https://github.com/TypeType-Video/TypeType/issues/103"
    ),
    DemoAdminIssue(
      id: "BUG-101",
      title: "Import archive summary",
      category: "Import",
      status: "Resolved",
      reporter: "demo@typetype.video",
      detail: "The summary should include skipped duplicate entries.",
      diagnostics: "PipePipe import · local fixture",
      githubIssue: nil
    ),
  ]
}
