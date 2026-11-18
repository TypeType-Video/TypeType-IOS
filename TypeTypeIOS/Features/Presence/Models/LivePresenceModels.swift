import Foundation

struct LivePresenceKey: Decodable, Equatable, Identifiable {
  let id: String
  let name: String
  let tokenPrefix: String
  let createdAt: Int64
  let lastUsedAt: Int64?
}

struct LivePresenceKeyCreated: Decodable, Equatable {
  let key: LivePresenceKey
  let token: String
}
