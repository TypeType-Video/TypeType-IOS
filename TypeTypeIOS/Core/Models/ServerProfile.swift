import Foundation

struct ServerProfile: Codable, Hashable, Identifiable {
  let id: String
  let name: String
  let baseURLString: String
  let createdAt: Date

  var baseURL: URL? {
    URL(string: baseURLString)
  }

  init(
    id: String = UUID().uuidString,
    name: String,
    baseURLString: String,
    createdAt: Date = .now
  ) {
    self.id = id
    self.name = name
    self.baseURLString = baseURLString
    self.createdAt = createdAt
  }
}
