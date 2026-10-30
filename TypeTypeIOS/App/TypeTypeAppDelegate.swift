import UIKit
import UserNotifications

final class TypeTypeAppDelegate: NSObject, UIApplicationDelegate {
  let orientationLock = LiveOrientationLock()
  let backgroundRefresh = LiveBackgroundRefreshCoordinator()
  let crashReports = LiveCrashReportArchive()
  private lazy var crashReporter = LiveCrashReporter(archive: crashReports)

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Background tasks must be registered before launch finishes.
    backgroundRefresh.registerIfNeeded()
    crashReporter.start()
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    orientationLock.mask
  }
}

extension TypeTypeAppDelegate: UNUserNotificationCenterDelegate {
  // Opened as an incoming link, so a tap goes through the same routing as a TypeType link from another app.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    guard let value = response.notification.request.content.userInfo["url"] as? String,
      let url = URL(string: value)
    else { return }
    await MainActor.run { UIApplication.shared.open(url, options: [:], completionHandler: nil) }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .list, .sound]
  }
}
