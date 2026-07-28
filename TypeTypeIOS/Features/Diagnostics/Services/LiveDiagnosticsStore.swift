import CryptoKit
import Foundation

actor LiveDiagnosticsStore {
  private let fileManager: FileManager
  private let rootURL: URL
  private let maximumEntries: Int

  init(
    rootURL: URL = LiveDiagnosticsStore.defaultRootURL(),
    fileManager: FileManager = .default,
    maximumEntries: Int = 200
  ) {
    self.rootURL = rootURL
    self.fileManager = fileManager
    self.maximumEntries = maximumEntries
  }

  func record(
    scope: LiveDiagnosticScope,
    method: String,
    requestURL: URL,
    baseURL: URL,
    statusCode: Int?,
    durationMilliseconds: Int64,
    requestID: String?
  ) {
    guard let route = Self.route(
      for: requestURL,
      relativeTo: baseURL
    ) else {
      return
    }
    var entries = load(scope: scope)
    entries.append(
      LiveDiagnosticEntry(
        id: UUID().uuidString,
        timestamp: Date(),
        method: Self.safeMethod(method),
        route: route,
        statusCode: statusCode.flatMap {
          (100...599).contains($0) ? $0 : nil
        },
        durationMilliseconds: min(
          max(durationMilliseconds, 0),
          3_600_000
        ),
        requestID: Self.safeRequestID(requestID)
      )
    )
    if entries.count > maximumEntries {
      entries.removeFirst(entries.count - maximumEntries)
    }
    persist(entries, scope: scope)
  }

  func entries(
    for scope: LiveDiagnosticScope
  ) -> [LiveDiagnosticEntry] {
    load(scope: scope).reversed()
  }

  func clear(scope: LiveDiagnosticScope) {
    try? fileManager.removeItem(at: fileURL(for: scope))
  }

  nonisolated static func resetPersistentState(
    fileManager: FileManager = .default
  ) {
    try? fileManager.removeItem(at: defaultRootURL())
  }

  nonisolated static func route(
    for requestURL: URL,
    relativeTo baseURL: URL
  ) -> String? {
    guard requestURL.scheme?.lowercased() == baseURL.scheme?.lowercased(),
      requestURL.host?.lowercased() == baseURL.host?.lowercased(),
      requestURL.port == baseURL.port
    else {
      return nil
    }
    let base = baseURL.pathComponents.filter(Self.isRouteSegment)
    let requested = requestURL.pathComponents.filter(Self.isRouteSegment)
    guard requested.starts(with: base) else { return nil }
    let relative = Array(requested.dropFirst(base.count))
    guard !relative.isEmpty else { return "/" }

    if relative.starts(with: ["sabr", "playback"]) {
      let operation = relative.dropFirst(3).first
      return ["/sabr", "playback", operation]
        .compactMap { $0 }
        .joined(separator: "/")
    }
    if relative.starts(with: ["downloader", "jobs"]) {
      let operation = relative.dropFirst(3).first
      return ["/downloader", "jobs", operation]
        .compactMap { $0 }
        .joined(separator: "/")
    }

    var sanitized: [String] = []
    for segment in relative.prefix(4) {
      let value = segment.lowercased()
      let safe = staticSegments.contains(value) ? value : ":id"
      if sanitized.last != safe || safe != ":id" {
        sanitized.append(safe)
      }
    }
    return "/" + sanitized.joined(separator: "/")
  }

  private func load(
    scope: LiveDiagnosticScope
  ) -> [LiveDiagnosticEntry] {
    guard let data = try? Data(contentsOf: fileURL(for: scope)),
      let entries = try? JSONDecoder().decode(
        [LiveDiagnosticEntry].self,
        from: data
      )
    else {
      return []
    }
    return entries
  }

  private func persist(
    _ entries: [LiveDiagnosticEntry],
    scope: LiveDiagnosticScope
  ) {
    do {
      try fileManager.createDirectory(
        at: rootURL,
        withIntermediateDirectories: true
      )
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys]
      try encoder.encode(entries).write(
        to: fileURL(for: scope),
        options: .atomic
      )
    } catch {
      AppLogger.app.error(
        "Diagnostics persistence failed: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  private func fileURL(
    for scope: LiveDiagnosticScope
  ) -> URL {
    let value = "\(scope.serverID)\u{0}\(scope.accountID)"
    let digest = SHA256.hash(data: Data(value.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
    return rootURL.appendingPathComponent("\(digest).json")
  }

  private nonisolated static func safeMethod(
    _ value: String
  ) -> String {
    let uppercased = value.uppercased()
    return ["GET", "POST", "PUT", "PATCH", "DELETE"]
      .contains(uppercased) ? uppercased : "OTHER"
  }

  private nonisolated static func safeRequestID(
    _ value: String?
  ) -> String? {
    guard let value,
      (8...128).contains(value.count),
      value.unicodeScalars.allSatisfy({
        CharacterSet.alphanumerics
          .union(CharacterSet(charactersIn: "-_.:"))
          .contains($0)
      })
    else {
      return nil
    }
    return value
  }

  private nonisolated static func isRouteSegment(
    _ value: String
  ) -> Bool {
    value != "/"
  }

  private nonisolated static let staticSegments: Set<String> = [
    "admin", "allowed", "artifact", "auth", "avatar",
    "blocked", "bootstrap", "bug-reports", "bullet-comments",
    "callback", "cancel", "channel", "channels", "comments",
    "complete", "dearrow", "deep", "downloader", "events",
    "favorites", "feed", "filters", "github-issue", "guest",
    "health", "history", "home", "imports", "instance",
    "login", "logout", "managed-access", "me", "notifications",
    "oidc", "pairing", "playback", "playlists", "podcasts",
    "position", "prefetch", "profile", "progress", "public",
    "recommendations", "refresh", "register", "replies",
    "reset-password", "sabr", "saved-playlists", "search",
    "search-history", "segments", "sessions", "settings",
    "start", "status", "stop", "streams", "subscriptions",
    "suggestions", "thumbnail", "trending", "unread-count",
    "users", "watch-later", "window", "youtube",
    "youtube-session", "youtube-takeout",
  ]

  nonisolated private static func defaultRootURL() -> URL {
    let base = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first ?? FileManager.default.temporaryDirectory
    return base
      .appendingPathComponent("TypeType", isDirectory: true)
      .appendingPathComponent("Diagnostics", isDirectory: true)
  }
}
