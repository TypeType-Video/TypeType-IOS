import Foundation

struct SessionSnapshot: Codable, Hashable {
  let serverID: String
  let userID: String
  let accountIdentifier: String?
  let publicUsername: String?
  let role: String
  let updatedAt: Date

  init(
    serverID: String,
    userID: String,
    accountIdentifier: String?,
    publicUsername: String? = nil,
    role: String,
    updatedAt: Date = .now
  ) {
    self.serverID = serverID
    self.userID = userID
    self.accountIdentifier = accountIdentifier
    self.publicUsername = publicUsername
    self.role = role
    self.updatedAt = updatedAt
  }

  private enum CodingKeys: String, CodingKey {
    case serverID
    case userID
    case accountIdentifier
    case legacyUserEmail = "userEmail"
    case publicUsername
    case role
    case updatedAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    serverID = try container.decode(String.self, forKey: .serverID)
    userID = try container.decode(String.self, forKey: .userID)
    accountIdentifier =
      try container.decodeIfPresent(
        String.self,
        forKey: .accountIdentifier
      )
      ?? container.decodeIfPresent(
        String.self,
        forKey: .legacyUserEmail
      )
    publicUsername = try container.decodeIfPresent(
      String.self,
      forKey: .publicUsername
    )
    role = try container.decode(String.self, forKey: .role)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(serverID, forKey: .serverID)
    try container.encode(userID, forKey: .userID)
    try container.encodeIfPresent(
      accountIdentifier,
      forKey: .accountIdentifier
    )
    try container.encodeIfPresent(
      publicUsername,
      forKey: .publicUsername
    )
    try container.encode(role, forKey: .role)
    try container.encode(updatedAt, forKey: .updatedAt)
  }
}
