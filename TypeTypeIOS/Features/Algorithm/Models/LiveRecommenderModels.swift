import Foundation

enum LiveRecommenderValue: Codable, Equatable {
  case number(Double)
  case flag(Bool)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let flag = try? container.decode(Bool.self) {
      self = .flag(flag)
    } else {
      self = .number(try container.decode(Double.self))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .number(value): try container.encode(value)
    case let .flag(value): try container.encode(value)
    }
  }
}

struct LiveRecommenderSettings: Codable, Equatable {
  var enabled = false
  var algorithmID: String?
  var parameters: [String: LiveRecommenderValue] = [:]
  var mutedGroups: [String] = []
  var ignoredSignals: [String] = []
  var pinnedGroups: [String] = []
  var sessionResetAt: Int64?
  var customInterests: [String] = []
  var unusedData: [String] = []
  var excludedItems: [String] = []
  var retentionDays: [String: Int] = [:]

  private enum CodingKeys: String, CodingKey {
    case enabled, parameters, mutedGroups, ignoredSignals, pinnedGroups, sessionResetAt, customInterests
    case unusedData, excludedItems, retentionDays
    case algorithmID = "algorithmId"
  }

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    enabled = try values.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
    algorithmID = try values.decodeIfPresent(String.self, forKey: .algorithmID)
    parameters = try values.decodeIfPresent([String: LiveRecommenderValue].self, forKey: .parameters) ?? [:]
    mutedGroups = try values.decodeIfPresent([String].self, forKey: .mutedGroups) ?? []
    ignoredSignals = try values.decodeIfPresent([String].self, forKey: .ignoredSignals) ?? []
    pinnedGroups = try values.decodeIfPresent([String].self, forKey: .pinnedGroups) ?? []
    sessionResetAt = try values.decodeIfPresent(Int64.self, forKey: .sessionResetAt)
    customInterests = try values.decodeIfPresent([String].self, forKey: .customInterests) ?? []
    unusedData = try values.decodeIfPresent([String].self, forKey: .unusedData) ?? []
    excludedItems = try values.decodeIfPresent([String].self, forKey: .excludedItems) ?? []
    retentionDays = try values.decodeIfPresent([String: Int].self, forKey: .retentionDays) ?? [:]
  }
}

struct LiveRecommenderParameter: Decodable, Equatable, Identifiable {
  let id: String
  let group: String
  let label: String
  let type: String
  let min: Double?
  let max: Double?
  let step: Double?
  let defaultValue: LiveRecommenderValue
  let unit: String?
  let help: String?

  private enum CodingKeys: String, CodingKey {
    case id, group, label, type, min, max, step, unit, help
    case defaultValue = "default"
  }
}

struct LiveRecommenderGuide: Decodable, Equatable {
  let forYouIf: String
  let youWillSee: String
  let goodToKnow: String

  private enum CodingKeys: String, CodingKey {
    case forYouIf = "for_you_if"
    case youWillSee = "you_will_see"
    case goodToKnow = "good_to_know"
  }
}

struct LiveRecommenderAlgorithm: Decodable, Equatable, Identifiable {
  let id: String
  let name: String
  let description: String
  let guide: LiveRecommenderGuide?
  let parameters: [LiveRecommenderParameter]
}

struct LiveRecommenderAlgorithms: Decodable, Equatable {
  let defaultAlgorithm: String?
  let algorithms: [LiveRecommenderAlgorithm]

  private enum CodingKeys: String, CodingKey {
    case algorithms
    case defaultAlgorithm = "default_algorithm"
  }
}

struct LiveRecommenderDataItem: Decodable, Equatable, Identifiable {
  let id: String
  let title: String
  let channel: String?
  let at: Int64
  let excluded: Bool
}

struct LiveRecommenderDataCategory: Decodable, Equatable, Identifiable {
  static let excludable: Set<String> = ["history", "shorts_history", "favorites"]
  static let retentionChoices: [Int?] = [7, 30, 90, 180, 365, nil]

  let id: String
  let count: Int
  let use: Bool
  let retentionDays: Int?
  let items: [LiveRecommenderDataItem]
}

struct LiveRecommenderTrace: Decodable, Equatable {
  struct Source: Decodable, Equatable {
    let kind: String
  }

  struct Row: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let why: String
    let videos: Int
  }

  let algorithm: String
  let builtAt: Int64
  let sources: [Source]
  let candidatesReceived: Int
  let dropped: [String: Int]
  let shown: Int
  let rows: [Row]
}

struct LiveRecommenderOpinion: Decodable, Equatable, Identifiable {
  let id: String
  let kind: String
  let verdict: String
  let comment: String?
  let videoURL: String?
  let reason: String?
  let title: String?
  let channelName: String?
  let algorithmID: String
  let createdAt: Int64

  private enum CodingKeys: String, CodingKey {
    case id, kind, verdict, comment, reason, title, channelName, createdAt
    case videoURL = "videoUrl"
    case algorithmID = "algorithmId"
  }
}
