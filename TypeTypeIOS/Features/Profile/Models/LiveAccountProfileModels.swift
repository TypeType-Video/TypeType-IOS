import Foundation

struct AccountProfileItem: Codable, Equatable, Identifiable {
  let id: String
  let name: String
  let isActive: Bool
  let isDefault: Bool
  let lastUsedAt: Int64
  let publicUsername: String?
  let avatarURL: URL?
  let avatarType: String?
  let avatarCode: String?

  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case isActive
    case isDefault
    case lastUsedAt
    case publicUsername
    case avatarURL = "avatarUrl"
    case avatarType
    case avatarCode
  }
}

struct AccountProfilesResponse: Codable, Equatable {
  let profiles: [AccountProfileItem]
  let activeProfileID: String
  let defaultProfileID: String

  private enum CodingKeys: String, CodingKey {
    case profiles
    case activeProfileID = "activeProfileId"
    case defaultProfileID = "defaultProfileId"
  }
}

struct ProfileNamePayload: Encodable, Equatable {
  let name: String
}

struct ProfileSwitchResponse: Codable, Equatable {
  let accessToken: String
  let profile: AccountProfileItem
}
