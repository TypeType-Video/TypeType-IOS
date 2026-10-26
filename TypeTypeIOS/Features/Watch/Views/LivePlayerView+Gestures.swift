import SwiftUI

extension LivePlayerView {
  /// YouTube-style: when the player scrolls away (reading comments), float
  /// it into Picture in Picture automatically. Edge-triggered: one start per
  /// scroll-away, re-armed when the player is visible again.
  func evaluateAutoPictureInPicture(_ frame: CGRect) {
    // Pull-down is only allowed while the page is at the top: the player
    // must sit below the status bar and well above the bottom edge.
    let screenH = UIScreen.main.bounds.height
    controller.isPlayerSurfaceFullyVisible =
      frame.minY >= 44 && frame.maxY <= screenH - 100
    let isAway = frame.maxY < frame.height * 0.3
    if !isAway {
      autoPictureInPictureArmed = true
      // Only auto-started PiP windows return here; a manual mini player stays.
      if autoPictureInPictureActive {
        autoPictureInPictureActive = false
        if controller.pictureInPicture.isEngaged {
          controller.pictureInPicture.bringInline()
        }
      }
      return
    }
    guard autoPictureInPictureArmed else { return }
    autoPictureInPictureArmed = false
    guard coordinator.hasActivePlayback,
      !controller.pictureInPicture.isEngaged
    else {
      return
    }
    autoPictureInPictureActive = true
    coordinator.startSystemPictureInPicture()
  }

  func handleDoubleTap(
    at location: CGPoint,
    width: CGFloat
  ) {
    guard
      !preferences.preferences.playerAccessibleControlsEnabled,
      preferences.preferences.playerDoubleTapSeekEnabled
    else {
      return
    }
    // The middle band holds the transport buttons.
    guard location.x < width * 0.35 || location.x > width * 0.65 else {
      return
    }
    guard let direction = PlayerDoubleTapSeek.direction(
      x: location.x,
      width: width
    ) else {
      return
    }
    // Build on the pending target: the position only moves once the seek has run.
    let pending = doubleTapSeek.flatMap {
      $0.direction == direction && Date().timeIntervalSince($0.at) < 1.5 ? $0 : nil
    }
    let step = preferences.preferences.playerDoubleTapSeekSeconds
    guard let target = PlayerDoubleTapSeek.target(
      current: pending?.target ?? controller.position,
      duration: controller.duration,
      direction: direction,
      seconds: step
    ) else {
      return
    }
    let seconds = (pending?.seconds ?? 0) + step
    doubleTapSeek = (target, seconds, direction, Date())
    seekFeedback = PlayerDoubleTapSeekFeedback(
      direction: direction,
      seconds: seconds
    )
    doubleTapSeekTask?.cancel()
    doubleTapSeekTask = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(450))
      guard !Task.isCancelled else { return }
      controller.seek(to: target)
    }
  }

  func handleSwipeAdjustment(
    _ event: PlayerSwipeAdjustmentEvent
  ) {
    guard preferences.preferences.playerSwipeBrightnessVolumeEnabled else {
      return
    }
    switch event {
    case let .began(kind, fraction):
      if kind == .brightness {
        systemBrightnessBeforeSwipe = UIScreen.main.brightness
      }
      swipeAdjustment = PlayerSwipeAdjustmentState(
        kind: kind,
        fraction: fraction
      )
    case let .updated(kind, fraction):
      swipeAdjustment = PlayerSwipeAdjustmentState(
        kind: kind,
        fraction: fraction
      )
      applySwipeAdjustment(kind: kind, fraction: fraction)
    case .ended:
      swipeAdjustment = nil
    }
  }

  func handleHorizontalSeek(
    _ event: PlayerHorizontalSeekEvent
  ) {
    switch event {
    case let .began(position):
      horizontalSeekPreview = position
    case let .updated(position):
      horizontalSeekPreview = position
    case let .ended(position):
      horizontalSeekPreview = nil
      controller.seek(to: position)
    }
  }

  func applySwipeAdjustment(
    kind: PlayerSwipeAdjustmentKind,
    fraction: CGFloat
  ) {
    switch kind {
    case .brightness:
      UIScreen.main.brightness = fraction
    case .volume:
      controller.player.volume = Float(fraction)
    }
  }

  func restoreSystemBrightness() {
    if let brightness = systemBrightnessBeforeSwipe {
      UIScreen.main.brightness = brightness
      systemBrightnessBeforeSwipe = nil
    }
  }

  func setLongPressBoost(active: Bool) {
    guard preferences.preferences.playerLongPressSpeedEnabled else { return }
    longPressBoostTask?.cancel()
    longPressBoostTask = nil
    if active {
      // Boost only after the long-press threshold, or every tap changes the rate twice.
      longPressBoostTask = Task {
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard !Task.isCancelled else { return }
        self.longPressBaseRate = self.controller.playbackRate
        self.controller.setPlaybackRate(2)
      }
    } else if let baseRate = longPressBaseRate {
      controller.setPlaybackRate(baseRate)
      longPressBaseRate = nil
    }
  }
}
