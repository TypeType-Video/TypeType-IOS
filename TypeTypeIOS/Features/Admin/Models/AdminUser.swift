import Foundation

enum AdminRole: String, Codable, CaseIterable {
  case admin
  case moderator
  case user
}

struct AdminUser: Decodable, Identifiable {
  let id: String
  let email: String
  let name: String
  let role: AdminRole
  let suspended: Bool
  let verified: Bool
  let createdAt: Int64OrString
}

struct AdminUsersPage: Decodable {
  let items: [AdminUser]
  let page: Int
  let limit: Int
  let total: Int
}

struct PasswordResetToken: Decodable {
  let resetToken: String
}
