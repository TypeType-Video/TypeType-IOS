import UIKit

// Asks iOS for a little time after the app leaves the screen. Ends at most once, when the work is done or when iOS
// takes the time back.
@MainActor
final class LiveBackgroundActivity {
  private var identifier = UIBackgroundTaskIdentifier.invalid

  init(name: String) {
    identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
      MainActor.assumeIsolated { self?.end() }
    }
  }

  func end() {
    guard identifier != .invalid else { return }
    UIApplication.shared.endBackgroundTask(identifier)
    identifier = .invalid
  }
}
