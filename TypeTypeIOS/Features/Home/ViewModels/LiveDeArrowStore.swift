import Foundation

@MainActor
final class LiveDeArrowStore: ObservableObject {
  @Published private var branding: [String: LiveVideoBranding] = [:]

  private let service: LiveDeArrowServiceProtocol
  private let settingsService: LiveSettingsServiceProtocol
  private var preferences: LiveSettings?
  private var preferencesTask: Task<LiveSettings, Error>?
  private var requests: Set<String> = []

  init(
    service: LiveDeArrowServiceProtocol,
    settingsService: LiveSettingsServiceProtocol
  ) {
    self.service = service
    self.settingsService = settingsService
  }

  func branding(for video: LiveVideoItem) -> LiveVideoBranding {
    branding[video.canonicalID] ?? LiveVideoBranding(
      title: video.title,
      thumbnailURL: video.thumbnail
    )
  }

  func prepare(_ video: LiveVideoItem) async {
    guard let videoID = Self.youTubeVideoID(video.url),
      !requests.contains(video.canonicalID)
    else {
      return
    }
    requests.insert(video.canonicalID)
    do {
      let settings = try await loadPreferences()
      guard settings.deArrowEnabled else { return }
      let item = try await service.item(videoID: videoID)
      branding[video.canonicalID] = resolve(
        item: item,
        video: video,
        settings: settings
      )
    } catch {
      return
    }
  }

  func invalidatePreferences() {
    preferencesTask?.cancel()
    preferencesTask = nil
    preferences = nil
    requests = []
    branding = [:]
  }

  private func loadPreferences() async throws -> LiveSettings {
    if let preferences {
      return preferences
    }
    if let preferencesTask {
      return try await preferencesTask.value
    }
    let task = Task { try await settingsService.settings() }
    preferencesTask = task
    do {
      let value = try await task.value
      preferences = value
      preferencesTask = nil
      return value
    } catch {
      preferencesTask = nil
      throw error
    }
  }

  private func resolve(
    item: LiveDeArrowItem,
    video: LiveVideoItem,
    settings: LiveSettings
  ) -> LiveVideoBranding {
    let trustedTitle = item.titles.first {
      trusted($0.locked, votes: $0.votes, mode: settings.deArrowTrustMode)
    }
    let title: String
    if settings.deArrowTitleMode == "original" {
      title = video.title
    } else if let trustedTitle {
      title = trustedTitle.original ? video.title : trustedTitle.title
    } else if settings.deArrowTrustMode != "locked" {
      title = item.title ?? video.title
    } else {
      title = video.title
    }

    let trustedThumbnail = item.thumbnails.first {
      trusted($0.locked, votes: $0.votes, mode: settings.deArrowTrustMode)
    }
    let communityThumbnail: URL?
    if let trustedThumbnail {
      communityThumbnail = trustedThumbnail.original
        ? video.thumbnail
        : service.absoluteURL(trustedThumbnail.thumbnailURL)
    } else if settings.deArrowTrustMode != "locked" {
      communityThumbnail = service.absoluteURL(item.thumbnailURL)
    } else {
      communityThumbnail = nil
    }
    let duration = item.videoDuration.flatMap { $0 > 0 ? $0 : nil }
      ?? (video.duration > 0 ? Double(video.duration) : nil)
    let randomThumbnail: URL?
    if let randomTime = item.randomTime,
      randomTime > 0,
      let duration,
      duration > 0 {
      randomThumbnail = service.thumbnailURL(
        videoID: item.videoID,
        time: randomTime * duration
      )
    } else {
      randomThumbnail = nil
    }

    let thumbnail: URL?
    switch settings.deArrowThumbnailMode {
    case "dearrow":
      thumbnail = communityThumbnail ?? video.thumbnail
    case "random":
      thumbnail = randomThumbnail ?? video.thumbnail
    case "original":
      thumbnail = video.thumbnail
    default:
      thumbnail =
        communityThumbnail ?? randomThumbnail ?? video.thumbnail
    }
    return LiveVideoBranding(title: title, thumbnailURL: thumbnail)
  }

  private func trusted(
    _ locked: Bool,
    votes: Int,
    mode: String
  ) -> Bool {
    mode == "locked" ? locked : locked || votes >= 0
  }

  private static func youTubeVideoID(_ value: String) -> String? {
    guard let components = URLComponents(string: value),
      let host = components.host?.lowercased()
    else {
      return nil
    }
    if host == "youtu.be" || host.hasSuffix(".youtu.be") {
      return components.path.split(separator: "/").first.map(String.init)
    }
    guard host == "youtube.com" || host.hasSuffix(".youtube.com") else {
      return nil
    }
    if let value = components.queryItems?.first(
      where: { $0.name == "v" }
    )?.value, !value.isEmpty {
      return value
    }
    let parts = components.path.split(separator: "/").map(String.init)
    guard let marker = parts.firstIndex(
      where: { ["shorts", "live", "embed"].contains($0) }
    ), parts.indices.contains(marker + 1) else {
      return nil
    }
    return parts[marker + 1]
  }
}
