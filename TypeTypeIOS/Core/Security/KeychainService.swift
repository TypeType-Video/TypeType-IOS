import Foundation
import Security

protocol KeychainService {
  func set(_ value: String, for account: String) -> Bool
  func get(_ account: String) -> String?
  func remove(_ account: String) -> Bool
}

final class SecureKeychainService: KeychainService {
  private let service: String

  init(service: String = AppConfig.accessTokenService) {
    self.service = service
  }

  func set(_ value: String, for account: String) -> Bool {
    guard let data = value.data(using: .utf8) else { return false }
    _ = remove(account)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
      kSecAttrAccessible as String:
        kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }

  func get(_ account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else { return nil }
    guard let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  func remove(_ account: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }
}
