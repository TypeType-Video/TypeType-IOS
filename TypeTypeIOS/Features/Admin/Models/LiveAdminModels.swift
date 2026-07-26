import Foundation

struct LiveAdminSettings: Codable, Equatable {
  var name: String
  var tagline: String?
  var logoURL: String?
  var bannerURL: String?
  var minimumAndroidClientVersion: String?
  var allowRegistration: Bool
  var allowGuest: Bool
  var forceEmailVerification: Bool
  var activeSessionsEnabled: Bool
  var localLoginEnabled: Bool
  var oidcAutoRedirect: Bool
  var youtubeRemoteLoginEnabled: Bool
  var accessMode: String

  private enum CodingKeys: String, CodingKey {
    case name, tagline
    case logoURL = "logoUrl"
    case bannerURL = "bannerUrl"
    case minimumAndroidClientVersion = "minAndroidClientVersion"
    case allowRegistration, allowGuest, forceEmailVerification
    case activeSessionsEnabled, localLoginEnabled, oidcAutoRedirect
    case youtubeRemoteLoginEnabled, accessMode
  }
}

struct LiveAdminUser: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let email: String
  let name: String
  let role: String
  let publicUsername: String?
  let bio: String?
  let avatarURL: URL?
  let avatarType: String?
  let avatarCode: String?
  let suspended: Bool
  let verified: Bool
  let accessMode: String
  let createdAt: Int64

  private enum CodingKeys: String, CodingKey {
    case id, email, name, role, publicUsername, bio
    case avatarURL = "avatarUrl"
    case avatarType, avatarCode, suspended, verified, accessMode, createdAt
  }
}

struct LiveAdminUsersPage: Decodable, Equatable {
  let items: [LiveAdminUser]
  let page: Int
  let limit: Int
  let total: Int64
}

struct LiveAdminRolePayload: Encodable {
  let role: String
}

struct LiveAdminIdentityPayload: Encodable {
  let email: String
  let name: String
}

struct LiveAdminResetToken: Decodable, Equatable {
  let resetToken: String
}
