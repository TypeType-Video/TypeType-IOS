import Foundation

enum AuthRole: String, Codable {
  case user
  case moderator
  case admin
}

struct AuthSessionResult {
  let userID: String
  let email: String
  let role: AuthRole
  let token: String
}

struct LoginPayload: Encodable {
  let identifier: String
  let password: String
}

struct RegisterPayload: Encodable {
  let name: String
  let email: String
  let password: String
}

struct RefreshPayload: Encodable {
  let token: String
}

struct AuthTokenResponse: Decodable {
  let token: String
}

struct AuthMeResponse: Decodable {
  let id: String
  let role: AuthRole
}
