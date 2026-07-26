import Foundation

struct LiveBugReportContext: Decodable, Equatable {
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

struct LiveAdminBugReportDetail: Decodable, Equatable {
  let id: String
  let category: String
  let description: String
  let status: String
  let userID: String
  let userEmail: String
  let context: LiveBugReportContext
  let githubIssueURL: URL?
  let createdAt: Int64
  let updatedAt: Int64

  private enum CodingKeys: String, CodingKey {
    case id, category, description, status
    case userID = "userId"
    case userEmail, context
    case githubIssueURL = "githubIssueUrl"
    case createdAt, updatedAt
  }
}

struct LiveBugReportStatusPayload: Encodable {
  let status: String
}

struct LiveBugReportStatusResult: Decodable {
  let id: String
  let status: String
  let updatedAt: Int64
}

struct LiveBugReportGitHubResult: Decodable {
  let id: String
  let githubIssueURL: URL
  let updatedAt: Int64

  private enum CodingKeys: String, CodingKey {
    case id
    case githubIssueURL = "githubIssueUrl"
    case updatedAt
  }
}
