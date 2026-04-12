import Foundation

enum DefaultServiceStore {
  private static let key = "typetype.default.service.id"

  static func get() -> Int {
    let value = UserDefaults.standard.object(forKey: key) as? Int
    return value ?? 0
  }

  static func set(_ serviceID: Int) {
    UserDefaults.standard.set(serviceID, forKey: key)
  }
}
