import Foundation

struct LiveAdminAllowListUser:
  Codable, Equatable, Hashable, Identifiable {
  let id: String
  let email: String
  let name: String
  let accessMode: String
  let adminManagedAccessMode: Bool?
}

struct LiveAdminManagedUsersPage: Decodable, Equatable {
  let items: [LiveAdminAllowListUser]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case items
    case nextPage = "nextpage"
  }
}

struct LiveAllowedPlaylistItem: Codable, Equatable, Identifiable {
  let url: String
  let title: String?
  let thumbnailURL: String?
  let uploaderName: String?
  let allowedAt: Int64
  let global: Bool?

  var id: String { url }

  private enum CodingKeys: String, CodingKey {
    case url, title
    case thumbnailURL = "thumbnailUrl"
    case uploaderName, allowedAt, global
  }

  init(
    url: String,
    title: String? = nil,
    thumbnailURL: String? = nil,
    uploaderName: String? = nil,
    allowedAt: Int64 = 0,
    global: Bool? = nil
  ) {
    self.url = url
    self.title = title
    self.thumbnailURL = thumbnailURL
    self.uploaderName = uploaderName
    self.allowedAt = allowedAt
    self.global = global
  }
}

struct LiveAdminUserAllowList: Decodable, Equatable {
  let user: LiveAdminAllowListUser
  let globalChannels: [LiveContentControlItem]
  let userChannels: [LiveContentControlItem]
  let globalPlaylists: [LiveAllowedPlaylistItem]
  let userPlaylists: [LiveAllowedPlaylistItem]
}

struct LiveAdminAccessModePayload: Codable {
  let accessMode: String
}
