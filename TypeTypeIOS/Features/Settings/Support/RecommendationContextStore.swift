import Foundation

enum RecommendationContextStore {
  private static let serviceKey = "typetype.recommendation.context.service"
  private static let intentKey = "typetype.recommendation.context.intent"

  static func set(serviceID: Int) {
    UserDefaults.standard.set(serviceID, forKey: serviceKey)
  }

  static func set(intent: String) {
    UserDefaults.standard.set(intent, forKey: intentKey)
  }

  static func serviceID() -> Int {
    let value = UserDefaults.standard.object(forKey: serviceKey) as? Int
    return value ?? DefaultServiceStore.get()
  }

  static func intent() -> String {
    let raw = (UserDefaults.standard.string(forKey: intentKey) ?? "auto")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return raw.isEmpty ? "auto" : raw
  }
}
