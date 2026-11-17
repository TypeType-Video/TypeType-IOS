import Foundation

// A Twitch live can stop on a gap the instance left in the playlist (a cut ad break) without any error. Like the web
// client, a stall that lasts reloads the live with fresh links, a bounded number of times.
@MainActor
final class LiveTwitchLiveSession {
  static let maximumAttempts = 6

  private let firstDelay: TimeInterval
  private let longestDelay: TimeInterval
  private var task: Task<Void, Never>?
  private(set) var attempts = 0
  // Off once the viewer rewinds: leaving the live must not save its edge over the moment they picked.
  var savesRecordingPosition = true

  init(firstDelay: TimeInterval = 6, longestDelay: TimeInterval = 30) {
    self.firstDelay = firstDelay
    self.longestDelay = longestDelay
  }

  func stalled(stillStalled: @escaping @MainActor () -> Bool, reload: @escaping @MainActor () -> Void) {
    guard task == nil, attempts < Self.maximumAttempts else { return }
    let delay = min(longestDelay, firstDelay * pow(2, Double(attempts)))
    task = Task { @MainActor [weak self] in
      guard (try? await Task.sleep(for: .seconds(delay))) != nil, let self else { return }
      task = nil
      guard stillStalled() else { return }
      attempts += 1
      reload()
    }
  }

  func playing() {
    task?.cancel()
    task = nil
    attempts = 0
  }
}
