import Foundation

enum LivePortabilityDirection: String, Codable, CaseIterable, Identifiable {
  case export
  case `import`

  var id: String { rawValue }
}

enum LivePortabilityFidelity: String, Codable {
  case complete
  case partial
}

enum LivePortabilityDuplicatePolicy: String, Codable, CaseIterable, Identifiable {
  case skip
  case replace

  var id: String { rawValue }

  var title: String { self == .skip ? "Skip" : "Replace" }
}

enum LivePortabilityJobState: String, Codable {
  case queued
  case analyzing
  case ready
  case applying
  case encoding
  case completed
  case failed
  case cancelled
}

struct LivePortabilityCapability: Codable, Equatable, Hashable {
  let category: String
  let directions: [String]
  let fidelity: LivePortabilityFidelity
}

struct LivePortabilityFormat: Codable, Equatable, Hashable, Identifiable {
  let format: String
  let adapterVersion: Int
  let capabilities: [LivePortabilityCapability]
  let defaultExtension: String
  let contentType: String

  var id: String { format }

  func supports(
    direction: LivePortabilityDirection,
    category: LiveTypeTypeBackupCategory
  ) -> Bool {
    capabilities.contains {
      $0.category == category.rawValue && $0.directions.contains(
        direction.rawValue
      )
    }
  }
}

struct LivePortabilityDetection: Codable, Equatable {
  let format: String
  let formatVersion: String?
  let adapterVersion: Int
  let confidence: Double
  let evidence: String
}

struct LivePortabilityIssue: Codable, Equatable, Identifiable {
  let category: String?
  let code: String
  let message: String
  let count: Int

  var id: String { "\(category ?? "-"):\(code):\(message)" }
}

struct LivePortabilityPreview: Codable, Equatable {
  let detection: LivePortabilityDetection?
  let counts: [String: Int]
  let duplicates: Int
  let issues: [LivePortabilityIssue]
}

struct LivePortabilityProgress: Codable, Equatable {
  let phase: String?
  let unit: String?
  let processed: Int
  let total: Int?
}

struct LivePortabilityJob: Codable, Equatable, Identifiable {
  let id: String
  let kind: LivePortabilityDirection
  let state: LivePortabilityJobState
  let createdAt: Int64
  let updatedAt: Int64
  let requestId: String?
  let preview: LivePortabilityPreview?
  let result: [String: Int]
  let progress: LivePortabilityProgress?
  let errorCode: String?
  let errorMessage: String?

  var isTerminal: Bool {
    state == .completed || state == .failed || state == .cancelled
  }
}

struct LivePortabilityExportRequest: Encodable {
  let format: String
  let categories: [String]
}

struct LivePortabilityApplyRequest: Encodable {
  let categories: [String]
  let duplicatePolicy: String
}
