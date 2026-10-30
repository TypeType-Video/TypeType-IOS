import Foundation
import UserNotifications

enum LiveNotificationPermissionStatus: Equatable {
  case unknown
  case notDetermined
  case denied
  case granted
  case provisional
  case ephemeral
}

protocol LiveNotificationPermissionManaging {
  func currentStatus() async -> LiveNotificationPermissionStatus
  func requestAuthorization() async throws -> LiveNotificationPermissionStatus
}

struct LiveNotificationPermissionService: LiveNotificationPermissionManaging {
  private let center: UNUserNotificationCenter

  init(center: UNUserNotificationCenter = .current()) {
    self.center = center
  }

  func currentStatus() async -> LiveNotificationPermissionStatus {
    await Self.map(center.notificationSettings().authorizationStatus)
  }

  func requestAuthorization() async throws -> LiveNotificationPermissionStatus {
    let granted = try await center.requestAuthorization(
      options: [.alert, .badge, .sound]
    )
    let status = await Self.map(
      center.notificationSettings().authorizationStatus
    )
    return granted || status == .provisional ? status : .denied
  }

  private static func map(
    _ status: UNAuthorizationStatus
  ) -> LiveNotificationPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .denied: return .denied
    case .authorized, .provisional: return .granted
    case .ephemeral: return .ephemeral
    @unknown default: return .unknown
    }
  }
}
