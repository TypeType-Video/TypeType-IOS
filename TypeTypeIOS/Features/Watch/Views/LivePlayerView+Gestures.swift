import SwiftUI

extension LivePlayerView {
  func evaluateAutoPictureInPicture(_ frame: CGRect) {
    // Rotating into full screen moves this surface: that is not a scroll-away.
    guard !controller.isPresentingFullscreen else { return }
    let screenH = UIScreen.main.bounds.height
    controller.isPlayerSurfaceFullyVisible =
      frame.minY >= 44 && frame.maxY <= screenH - 100
    let isAway = frame.maxY <= 0
    if controller.nativePlayback != nil {
      controller.isVideoDocked = isAway
      autoPictureInPictureArmed = !isAway
      return
    }
    if !isAway {
      autoPictureInPictureArmed = true
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
    LivePlayerView.logGesture("doubleTap x=\(Int(location.x))")
    guard
      !accessibleControls,
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
    // Build on the last target: the reported position lags behind a seek that is still loading.
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
    controller.seek(to: target)
  }

  func handleSwipeAdjustment(
    _ event: PlayerSwipeAdjustmentEvent
  ) {
    if case let .began(kind, _) = event {
      LivePlayerView.logGesture("swipe began \(kind)")
    }
    guard !accessibleControls, preferences.preferences.playerSwipeBrightnessVolumeEnabled else {
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

  func applySpeedRamp(translationHeight: CGFloat) {
    guard longPressBaseRate != nil else { return }
    let raw = 2.0 + (-translationHeight / 200.0) * 2.0
    let stepped = (raw * 2).rounded() / 2
    let rate = Float(min(max(stepped, 1), 4))
    speedBoostRate = rate
    controller.setPlaybackRate(rate)
  }

  func handleHorizontalSeek(
    _ event: PlayerHorizontalSeekEvent
  ) {
    switch event {
    case let .began(position):
      horizontalSeekPreview = (position, false)
    case let .updated(position, isFine):
      horizontalSeekPreview = (position, isFine)
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
      systemVolume.set(fraction)
    }
  }

  func restoreSystemBrightness() {
    if let brightness = systemBrightnessBeforeSwipe {
      UIScreen.main.brightness = brightness
      systemBrightnessBeforeSwipe = nil
    }
  }

  func beginSpeedRamp() {
    guard !accessibleControls, preferences.preferences.playerLongPressSpeedEnabled,
      longPressBaseRate == nil, swipeAdjustment == nil, horizontalSeekPreview == nil
    else { return }
    LivePlayerView.logGesture("speedRamp ON")
    longPressBaseRate = controller.playbackRate
    speedBoostRate = 2
    controller.setPlaybackRate(2)
  }

  func endSpeedRamp() {
    guard let baseRate = longPressBaseRate else { return }
    LivePlayerView.logGesture("speedRamp OFF")
    controller.setPlaybackRate(baseRate)
    longPressBaseRate = nil
    speedBoostRate = nil
  }
}
