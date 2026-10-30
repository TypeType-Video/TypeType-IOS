import Foundation

struct LiveContentControlItem: Codable, Equatable, Hashable, Identifiable {
  let url: String
  let name: String?
  let thumbnailURL: String?
  let timestamp: Int64
  let global: Bool?

  var id: String { url }

  private enum CodingKeys: String, CodingKey {
    case url, name
    case thumbnailURL = "thumbnailUrl"
    case blockedAt, allowedAt, global
  }

  init(
    url: String,
    name: String? = nil,
    thumbnailURL: String? = nil,
    timestamp: Int64 = 0,
    global: Bool? = nil
  ) {
    self.url = url
    self.name = name
    self.thumbnailURL = thumbnailURL
    self.timestamp = timestamp
    self.global = global
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    url = try values.decode(String.self, forKey: .url)
    name = try values.decodeIfPresent(String.self, forKey: .name)
    thumbnailURL = try values.decodeIfPresent(
      String.self,
      forKey: .thumbnailURL
    )
    let blockedAt = try values.decodeIfPresent(
      Int64.self,
      forKey: .blockedAt
    )
    let allowedAt = try values.decodeIfPresent(
      Int64.self,
      forKey: .allowedAt
    )
    timestamp = blockedAt ?? allowedAt ?? 0
    global = try values.decodeIfPresent(Bool.self, forKey: .global)
  }

  func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: CodingKeys.self)
    try values.encode(url, forKey: .url)
    try values.encodeIfPresent(name, forKey: .name)
    try values.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
    try values.encodeIfPresent(global, forKey: .global)
  }
}

enum LiveContentControlKind: String, CaseIterable, Identifiable {
  case blockedChannels
  case blockedVideos
  case blockedKeywords
  case allowedChannels

  var id: String { rawValue }

  var title: String {
    switch self {
    case .blockedChannels: return "Blocked channels"
    case .blockedVideos: return "Blocked videos"
    case .blockedKeywords: return "Blocked keywords"
    case .allowedChannels: return "Allowed channels"
    }
  }

  var icon: String {
    switch self {
    case .blockedChannels: "person.crop.circle.badge.xmark"
    case .blockedVideos: "play.slash"
    case .blockedKeywords: "textformat"
    case .allowedChannels: "checkmark.shield"
    }
  }

  var summary: String {
    switch self {
    case .blockedChannels: "Their videos never show up"
    case .blockedVideos: "Hidden everywhere in the app"
    case .blockedKeywords: "Videos whose title contains them are hidden"
    case .allowedChannels: "Channels kept even when others are limited"
    }
  }

  var addTitle: String {
    switch self {
    case .blockedChannels: String(localized: "Block a channel")
    case .blockedVideos: String(localized: "Block a video")
    case .blockedKeywords: String(localized: "Block a keyword")
    case .allowedChannels: String(localized: "Allow a channel")
    }
  }

  var emptyTitle: String {
    switch self {
    case .blockedChannels: String(localized: "No blocked channels")
    case .blockedVideos: String(localized: "No blocked videos")
    case .blockedKeywords: String(localized: "No blocked keywords")
    case .allowedChannels: String(localized: "No allowed channels")
    }
  }
}

extension LiveContentControlItem {
  var serviceName: String {
    VideoService.hosting(url)?.name ?? URL(string: url)?.host() ?? url
  }
}
