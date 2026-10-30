import Foundation

enum LivePortabilityDirection: String, Codable, CaseIterable, Identifiable {
  case export
  case `import`

  var id: String { rawValue }

  init(from decoder: Decoder) throws {
    let raw = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
    self = LivePortabilityDirection(rawValue: raw) ?? .export
  }
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

  init(from decoder: Decoder) throws {
    let raw = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
    self = LivePortabilityJobState(rawValue: raw) ?? .queued
  }
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

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    detection = try values.decodeIfPresent(
      LivePortabilityDetection.self,
      forKey: .detection
    )
    counts = try values.decodeIfPresent([String: Int].self, forKey: .counts) ?? [:]
    duplicates = try values.decodeIfPresent(Int.self, forKey: .duplicates) ?? 0
    issues = try values.decodeIfPresent(
      [LivePortabilityIssue].self,
      forKey: .issues
    ) ?? []
  }
}

struct LivePortabilityProgress: Codable, Equatable {
  let phase: String?
  let unit: String?
  let processed: Int
  let total: Int?

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    phase = try values.decodeIfPresent(String.self, forKey: .phase)
    unit = try values.decodeIfPresent(String.self, forKey: .unit)
    processed = try values.decodeIfPresent(Int.self, forKey: .processed) ?? 0
    total = try values.decodeIfPresent(Int.self, forKey: .total)
  }
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

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    kind = try values.decodeIfPresent(
      LivePortabilityDirection.self,
      forKey: .kind
    ) ?? .export
    state = try values.decodeIfPresent(
      LivePortabilityJobState.self,
      forKey: .state
    ) ?? .queued
    createdAt = try values.decodeIfPresent(Int64.self, forKey: .createdAt) ?? 0
    updatedAt = try values.decodeIfPresent(Int64.self, forKey: .updatedAt) ?? 0
    requestId = try values.decodeIfPresent(String.self, forKey: .requestId)
    preview = try values.decodeIfPresent(
      LivePortabilityPreview.self,
      forKey: .preview
    )
    result = try values.decodeIfPresent([String: Int].self, forKey: .result) ?? [:]
    progress = try values.decodeIfPresent(
      LivePortabilityProgress.self,
      forKey: .progress
    )
    errorCode = try values.decodeIfPresent(String.self, forKey: .errorCode)
    errorMessage = try values.decodeIfPresent(String.self, forKey: .errorMessage)
  }

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
