import SwiftUI

extension LivePlayerView {
  /// YouTube-style: when the player scrolls away (reading comments), float
  /// it into Picture in Picture automatically. Edge-triggered: one start per
  /// scroll-away, re-armed when the player is visible again.
  func evaluateAutoPictureInPicture(_ frame: CGRect) {
    // Pull-down is only allowed while the page is at the top: the player
    // must sit below the status bar and well above the bottom edge.
    // Rotating into full screen moves this surface; that is not the reader scrolling away.
    // The landscape stage owns the layer; everything else may float away.
    guard !controller.isPresentingFullscreen else { return }
    let screenH = UIScreen.main.bounds.height
    controller.isPlayerSurfaceFullyVisible =
      frame.minY >= 44 && frame.maxY <= screenH - 100
    // Dev spec: PiP only when the box is FULLY out of view, and back the
    // moment any part of it re-enters the viewport.
    let isAway = frame.maxY <= 0
    if controller.nativePlayback != nil {
      // The in-house player docks into an in-app corner card instead of the
      // system PiP: no scene hand-off (that was the app-wide stall), no
      // window flying, and the video stays in this window.
      controller.isVideoDocked = isAway
      autoPictureInPictureArmed = !isAway
      return
    }
    if !isAway {
      autoPictureInPictureArmed = true
      // Only auto-started PiP windows return here; a manual mini player
      // stays. The return waits until the player is about half re-entered,
      // so the window flies to a visible rect instead of an off-screen one.
      if autoPictureInPictureActive,
        frame.maxY >= frame.height * 0.5 {
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
    // While the long-press boost is held, the vertical drag ramps the
    // speed instead of volume/brightness (Android-style).
    let isEnded: Bool
    if case .ended = event { isEnded = true } else { isEnded = false }
    if longPressBaseRate != nil, !isEnded {
      if case let .began(_, fraction) = event { applySpeedRamp(fraction) }
      if case let .updated(_, fraction) = event { applySpeedRamp(fraction) }
      return
    }
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

  /// Hold baseline is 2x; the drag maps the fraction onto 1x–4x in
  /// half-step clicks. The HUD shows the live rate.
  func applySpeedRamp(_ fraction: CGFloat) {
    let steps = CGFloat(Int((fraction * 6).rounded()))
    let rate = Float(1 + steps * 0.5)
    speedBoostRate = rate
    controller.setPlaybackRate(rate)
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
      controller.setOutputVolume(Float(fraction))
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
        self.speedBoostRate = 2
        self.controller.setPlaybackRate(2)
      }
    } else if let baseRate = longPressBaseRate {
      controller.setPlaybackRate(baseRate)
      longPressBaseRate = nil
      speedBoostRate = nil
    }
  }
}
