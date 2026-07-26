import Foundation

struct AuthRole: RawRepresentable, Codable, Hashable {
  let rawValue: String

  static let user = AuthRole(rawValue: "user")
  static let moderator = AuthRole(rawValue: "moderator")
  static let admin = AuthRole(rawValue: "admin")
}

struct AuthUser: Decodable, Equatable {
  let id: String
  let role: AuthRole
  let publicUsername: String?
  let bio: String?
  let avatarURL: URL?
  let avatarType: String?
  let avatarCode: String?

  private enum CodingKeys: String, CodingKey {
    case id
    case role
    case publicUsername
    case bio
    case avatarURL = "avatarUrl"
    case avatarType
    case avatarCode
  }

  init(
    id: String,
    role: AuthRole,
    publicUsername: String?,
    bio: String? = nil,
    avatarURL: URL? = nil,
    avatarType: String? = nil,
    avatarCode: String? = nil
  ) {
    self.id = id
    self.role = role
    self.publicUsername = publicUsername
    self.bio = bio
    self.avatarURL = avatarURL
    self.avatarType = avatarType
    self.avatarCode = avatarCode
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    role = AuthRole(
      rawValue: try container.decodeIfPresent(
        String.self,
        forKey: .role
      ) ?? AuthRole.user.rawValue
    )
    publicUsername = try container.decodeIfPresent(
      String.self,
      forKey: .publicUsername
    )
    bio = try container.decodeIfPresent(String.self, forKey: .bio)
    avatarURL = try container.decodeIfPresent(
      URL.self,
      forKey: .avatarURL
    )
    avatarType = try container.decodeIfPresent(
      String.self,
      forKey: .avatarType
    )
    avatarCode = try container.decodeIfPresent(
      String.self,
      forKey: .avatarCode
    )
  }
}

struct AuthSessionResult: Equatable {
  let user: AuthUser
  let accountIdentifier: String?
  let accessToken: String
}

struct LoginPayload: Encodable {
  let identifier: String
  let password: String
}

struct RegisterPayload: Encodable {
  let email: String
  let password: String
  let name: String
}

struct RegisterStatus: Decodable, Equatable {
  let allowRegistration: Bool
  let bootstrapAvailable: Bool
  let localLoginEnabled: Bool
}

struct AuthAccessTokenResponse: Decodable, Equatable {
  let accessToken: String

  private enum CodingKeys: String, CodingKey {
    case accessToken
    case token
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let value =
      try container.decodeIfPresent(String.self, forKey: .accessToken)
      ?? container.decodeIfPresent(String.self, forKey: .token)
    guard let value, !value.isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .accessToken,
        in: container,
        debugDescription: "Authentication response has no access token."
      )
    }
    accessToken = value
  }
}

struct EmptyJSONPayload: Encodable {}
