import Foundation

struct LiveDiagnosticScope: Codable, Equatable, Hashable {
  let serverID: String
  let accountID: String
}

struct LiveDiagnosticEntry: Codable, Equatable, Identifiable {
  let id: String
  let timestamp: Date
  let method: String
  let route: String
  let statusCode: Int?
  let durationMilliseconds: Int64
  let requestID: String?

  var isFailure: Bool {
    statusCode == nil || (statusCode ?? 0) >= 400
  }
}
