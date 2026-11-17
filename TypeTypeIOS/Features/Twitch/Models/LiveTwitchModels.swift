import Foundation

struct LiveTwitchPage<Item: Decodable>: Decodable {
  let items: [Item]
  let cursor: String?
  let hasMore: Bool

  init(items: [Item], cursor: String?, hasMore: Bool) {
    self.items = items
    self.cursor = cursor
    self.hasMore = hasMore
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    items = try values.decodeIfPresent([Item].self, forKey: .items) ?? []
    cursor = try values.decodeIfPresent(String.self, forKey: .cursor)
    hasMore = try values.decodeIfPresent(Bool.self, forKey: .hasMore) ?? false
  }

  private enum CodingKeys: String, CodingKey {
    case items, cursor, hasMore
  }
}

struct LiveTwitchUser: Decodable, Hashable {
  let id: String
  let login: String
  let displayName: String
  let avatarURL: String

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
    login = try values.decodeIfPresent(String.self, forKey: .login) ?? ""
    displayName = try values.decodeIfPresent(String.self, forKey: .displayName) ?? login
    avatarURL = try values.decodeIfPresent(String.self, forKey: .avatarURL) ?? ""
  }

  var name: String { displayName.isEmpty ? login : displayName }

  private enum CodingKeys: String, CodingKey {
    case id, login, displayName
    case avatarURL = "avatarUrl"
  }
}

struct LiveTwitchGame: Decodable, Hashable, Identifiable {
  let id: String
  let name: String
  let slug: String
  let boxArtURL: String?
  let viewers: Int?
  let channels: Int?

  private enum CodingKeys: String, CodingKey {
    case id, name, slug, viewers, channels
    case boxArtURL = "boxArtUrl"
  }
}

struct LiveTwitchArchive: Decodable, Hashable {
  let id: String
  let startedAt: String
}

struct LiveTwitchStream: Decodable, Hashable, Identifiable {
  let id: String
  let title: String
  let user: LiveTwitchUser
  let game: LiveTwitchGame?
  let viewers: Int
  let previewURL: String
  let startedAt: String
  let tags: [String]
  let archive: LiveTwitchArchive?

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
    title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
    user = try values.decode(LiveTwitchUser.self, forKey: .user)
    game = try values.decodeIfPresent(LiveTwitchGame.self, forKey: .game)
    viewers = try values.decodeIfPresent(Int.self, forKey: .viewers) ?? 0
    previewURL = try values.decodeIfPresent(String.self, forKey: .previewURL) ?? ""
    startedAt = try values.decodeIfPresent(String.self, forKey: .startedAt) ?? ""
    tags = try values.decodeIfPresent([String].self, forKey: .tags) ?? []
    archive = try values.decodeIfPresent(LiveTwitchArchive.self, forKey: .archive)
  }

  private enum CodingKeys: String, CodingKey {
    case id, title, user, game, viewers, startedAt, tags, archive
    case previewURL = "previewUrl"
  }
}

struct LiveTwitchChannel: Decodable, Hashable {
  let user: LiveTwitchUser
  let description: String
  let bannerURL: String?
  let followers: Int
  let partner: Bool
  let live: LiveTwitchStream?

  init(from decoder: Decoder) throws {
    user = try LiveTwitchUser(from: decoder)
    let values = try decoder.container(keyedBy: CodingKeys.self)
    description = try values.decodeIfPresent(String.self, forKey: .description) ?? ""
    bannerURL = try values.decodeIfPresent(String.self, forKey: .bannerURL)
    followers = try values.decodeIfPresent(Int.self, forKey: .followers) ?? 0
    partner = try values.decodeIfPresent(Bool.self, forKey: .partner) ?? false
    live = try values.decodeIfPresent(LiveTwitchStream.self, forKey: .live)
  }

  private enum CodingKeys: String, CodingKey {
    case description, followers, partner, live
    case bannerURL = "bannerUrl"
  }
}

struct LiveTwitchVideo: Decodable, Hashable, Identifiable {
  let id: String
  let title: String
  let owner: LiveTwitchUser
  let game: LiveTwitchGame?
  let lengthSeconds: Int
  let views: Int
  let previewURL: String
  let createdAt: String
  let type: String
  let recording: Bool

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
    title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
    owner = try values.decode(LiveTwitchUser.self, forKey: .owner)
    game = try values.decodeIfPresent(LiveTwitchGame.self, forKey: .game)
    lengthSeconds = try values.decodeIfPresent(Int.self, forKey: .lengthSeconds) ?? 0
    views = try values.decodeIfPresent(Int.self, forKey: .views) ?? 0
    previewURL = try values.decodeIfPresent(String.self, forKey: .previewURL) ?? ""
    createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    type = try values.decodeIfPresent(String.self, forKey: .type) ?? ""
    recording = try values.decodeIfPresent(Bool.self, forKey: .recording) ?? false
  }

  private enum CodingKeys: String, CodingKey {
    case id, title, owner, game, lengthSeconds, views, createdAt, type, recording
    case previewURL = "previewUrl"
  }
}

struct LiveTwitchClip: Decodable, Hashable, Identifiable {
  let slug: String
  let title: String
  let broadcaster: LiveTwitchUser
  let game: LiveTwitchGame?
  let durationSeconds: Double
  let views: Int
  let thumbnailURL: String
  let createdAt: String

  var id: String { slug }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    slug = try values.decodeIfPresent(String.self, forKey: .slug) ?? ""
    title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
    broadcaster = try values.decode(LiveTwitchUser.self, forKey: .broadcaster)
    game = try values.decodeIfPresent(LiveTwitchGame.self, forKey: .game)
    durationSeconds = try values.decodeIfPresent(Double.self, forKey: .durationSeconds) ?? 0
    views = try values.decodeIfPresent(Int.self, forKey: .views) ?? 0
    thumbnailURL = try values.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
  }

  private enum CodingKeys: String, CodingKey {
    case slug, title, broadcaster, game, durationSeconds, views, createdAt
    case thumbnailURL = "thumbnailUrl"
  }
}

struct LiveTwitchGameStreams: Decodable {
  let game: LiveTwitchGame?
  let streams: LiveTwitchPage<LiveTwitchStream>
}

enum LiveTwitchSearchKind: String, CaseIterable, Identifiable {
  case channels, games, streams

  var id: String { rawValue }
}

extension LiveTwitchChannel: Identifiable {
  var id: String { user.id.isEmpty ? user.login : user.id }
}
