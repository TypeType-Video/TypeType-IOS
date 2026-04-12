import Foundation

enum RecommendationTrackingPreferenceStore {
  private static let key = "typetype.recommendation.tracking.enabled"

  static func get() -> Bool {
    if UserDefaults.standard.object(forKey: key) == nil {
      return true
    }
    return UserDefaults.standard.bool(forKey: key)
  }

  static func set(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: key)
  }
}
