import Foundation

struct SessionSnapshot: Codable, Hashable {
  let serverID: String
  let userID: String
  let userEmail: String
  let role: String
  let updatedAt: Date

  init(
    serverID: String,
    userID: String,
    userEmail: String,
    role: String,
    updatedAt: Date = .now
  ) {
    self.serverID = serverID
    self.userID = userID
    self.userEmail = userEmail
    self.role = role
    self.updatedAt = updatedAt
  }
}
