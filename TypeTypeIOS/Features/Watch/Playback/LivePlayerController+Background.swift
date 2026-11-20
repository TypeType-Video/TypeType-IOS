import AVFoundation
import UIKit

// With the screen off nobody sees the picture: the lowest HLS variant keeps the sound and saves data.
struct LiveBackgroundBitRate {
  static let background: Double = 1
  private(set) var saved: Double?

  mutating func enter(current: Double, showsPicture: Bool) -> Double? {
    guard !showsPicture, saved == nil else { return nil }
    saved = current
    return Self.background
  }

  mutating func leave() -> Double? {
    defer { saved = nil }
    return saved
  }
}

extension LivePlayerController {
  func observeBackgroundTransitions() {
    let center = NotificationCenter.default
    audioEvents.observations += [
      center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.enteredBackground() }
      },
      center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.returnedToForeground() }
      },
    ]
  }

  private func enteredBackground() {
    guard nativePlayback == nil, let item = player.currentItem else { return }
    let showsPicture = pictureInPicture.isEngaged || pictureInPicture.isPendingStart || pictureInPicture.isSystemActive
    guard let cap = audioEvents.bitRate.enter(current: item.preferredPeakBitRate, showsPicture: showsPicture) else { return }
    item.preferredPeakBitRate = cap
    AppLogger.playback.notice("background: video capped to the lowest variant")
  }

  private func returnedToForeground() {
    guard let saved = audioEvents.bitRate.leave() else { return }
    player.currentItem?.preferredPeakBitRate = saved
  }
}
