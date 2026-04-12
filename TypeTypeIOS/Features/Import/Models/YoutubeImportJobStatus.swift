import Foundation

struct YoutubeImportJobStatus: Decodable {
  let jobID: String
  let status: String
  let phase: String
  let progress: Int
  let createdAt: Int64
  let updatedAt: Int64
  let expiresAt: Int64
  let error: String?

  private enum CodingKeys: String, CodingKey {
    case jobID = "jobId"
    case status
    case phase
    case progress
    case createdAt
    case updatedAt
    case expiresAt
    case error
  }
}
