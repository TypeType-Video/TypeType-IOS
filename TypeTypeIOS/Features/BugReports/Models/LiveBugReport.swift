import Foundation

struct LiveBugReportContextPayload: Encodable {
  let videoURL: String?
  let route: String
  let timestamp: Int64
  let userAgent: String
  let browserLanguage: String
  let crashLogs: [LiveBugCrashLog]
  let apiErrors: [LiveBugAPIError]

  private enum CodingKeys: String, CodingKey {
    case videoURL = "videoUrl"
    case route, timestamp, userAgent, browserLanguage
    case crashLogs, apiErrors
  }
}

struct LiveBugCrashLog: Codable, Equatable {
  let message: String
  let stack: String?
  let timestamp: Int64
}

struct LiveBugAPIError: Codable, Equatable {
  let requestID: String?
  let endpoint: String
  let status: Int
  let code: String?
  let message: String?
  let timestamp: Int64

  private enum CodingKeys: String, CodingKey {
    case requestID = "requestId"
    case endpoint, status, code, message, timestamp
  }
}

struct LiveCreateBugReportPayload: Encodable {
  let category: String
  let description: String
  let context: LiveBugReportContextPayload
}

struct LiveCreatedBugReport: Decodable, Equatable {
  let id: String
  let status: String
  let createdAt: Int64
}

struct LiveAdminBugReport: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let category: String
  let description: String
  let status: String
  let userID: String
  let userEmail: String
  let githubIssueURL: URL?
  let createdAt: Int64
  let updatedAt: Int64

  private enum CodingKeys: String, CodingKey {
    case id, category, description, status
    case userID = "userId"
    case userEmail
    case githubIssueURL = "githubIssueUrl"
    case createdAt, updatedAt
  }
}

struct LiveAdminBugReportsPage: Decodable, Equatable {
  let items: [LiveAdminBugReport]
  let page: Int
  let limit: Int
  let total: Int64
}
