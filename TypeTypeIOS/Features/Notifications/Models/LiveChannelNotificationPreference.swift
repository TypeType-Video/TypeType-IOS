import Foundation

struct LiveChannelNotificationPreference: Codable, Equatable, Identifiable {
  let channelURL: String
  var enabled: Bool
  let updatedAt: Int64

  var id: String {
    channelURL
  }

  private enum CodingKeys: String, CodingKey {
    case channelURL = "channelUrl"
    case enabled
    case updatedAt
  }

  func matches(channelURL target: String) -> Bool {
    let normalizedTarget = target.trimmingCharacters(
      in: CharacterSet(charactersIn: "/")
    )
    .lowercased()
    let normalizedValue = channelURL.trimmingCharacters(
      in: CharacterSet(charactersIn: "/")
    )
    .lowercased()
    return normalizedValue == normalizedTarget
      || normalizedTarget.hasSuffix(normalizedValue)
      || normalizedValue.hasSuffix(normalizedTarget)
  }
}

struct LiveChannelNotificationPreferencePayload: Encodable, Equatable {
  let channelURL: String
  let enabled: Bool

  private enum CodingKeys: String, CodingKey {
    case channelURL = "channelUrl"
    case enabled
  }
}
