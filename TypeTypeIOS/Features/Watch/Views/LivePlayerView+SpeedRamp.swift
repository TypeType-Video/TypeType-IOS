import SwiftUI

extension LivePlayerView {
  func applySpeedRamp(translationHeight: CGFloat) {
    guard longPressBaseRate != nil else { return }
    let raw = controller.settings.holdSpeed + (-translationHeight / 200.0) * 2.0
    let stepped = (raw * 2).rounded() / 2
    let rate = Float(min(max(stepped, 1), 4))
    speedBoostRate = rate
    controller.setPlaybackRate(rate)
  }

  func beginSpeedRamp() {
    guard !accessibleControls, !controller.isLiveStream, preferences.preferences.playerLongPressSpeedEnabled,
      longPressBaseRate == nil, swipeAdjustment == nil, horizontalSeekPreview == nil
    else { return }
    LivePlayerView.logGesture("speedRamp ON")
    longPressBaseRate = controller.playbackRate
    let rate = Float(controller.settings.holdSpeed)
    speedBoostRate = rate
    controller.setPlaybackRate(rate)
  }

  func endSpeedRamp() {
    guard let baseRate = longPressBaseRate else { return }
    LivePlayerView.logGesture("speedRamp OFF")
    controller.setPlaybackRate(baseRate)
    longPressBaseRate = nil
    speedBoostRate = nil
  }
}
