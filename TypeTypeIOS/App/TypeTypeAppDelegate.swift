import UIKit

final class TypeTypeAppDelegate: NSObject, UIApplicationDelegate {
  let orientationLock = LiveOrientationLock()
  let backgroundRefresh = LiveBackgroundRefreshCoordinator()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Background tasks must be registered before launch finishes.
    backgroundRefresh.registerIfNeeded()
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    orientationLock.mask
  }
}
