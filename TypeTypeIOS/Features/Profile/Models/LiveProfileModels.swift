import Foundation

struct LiveAccountIdentity: Decodable, Equatable {
  let email: String
  let name: String
  let managedByOIDC: Bool

  private enum CodingKeys: String, CodingKey {
    case email, name
    case managedByOIDC = "managedByOidc"
  }
}

struct LivePublicProfile: Decodable, Equatable {
  let publicUsername: String
  let bio: String?
  let avatarURL: URL?
  let avatarType: String?
  let avatarCode: String?

  private enum CodingKeys: String, CodingKey {
    case publicUsername, bio
    case avatarURL = "avatarUrl"
    case avatarType, avatarCode
  }
}

struct LiveCustomAvatar: Decodable, Equatable {
  let avatarURL: URL
  let mediaType: String
  let size: Int

  private enum CodingKeys: String, CodingKey {
    case avatarURL = "avatarUrl"
    case mediaType, size
  }
}

struct LiveProfilePayload: Encodable {
  let publicUsername: String?
  let bio: String?
}

struct LiveAccountIdentityPayload: Encodable {
  let email: String
  let name: String
  let currentPassword: String
}

struct LiveEmojiAvatarPayload: Encodable {
  let code: String
}
