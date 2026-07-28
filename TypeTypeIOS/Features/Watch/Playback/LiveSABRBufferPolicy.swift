import Foundation

enum LiveSABRBufferPolicy {
  static func goalMS(
    isLive: Bool,
    playbackRate: Float
  ) -> Int64 {
    let base = isLive ? liveGoalMS : videoOnDemandGoalMS
    let rate = min(max(playbackRate, 0.25), 4)
    return min(
      Int64(
        (Double(base) * Double(max(rate, 1))).rounded()
      ),
      maximumGoalMS
    )
  }

  static func refreshThresholdMS(
    for goalMS: Int64
  ) -> Int64 {
    min(goalMS, max(5_000, goalMS * 2 / 3))
  }

  static func nativeLiveRefreshThresholdMS(
    for goalMS: Int64
  ) -> Int64 {
    max(goalMS, liveGoalMS)
  }

  static func nativeLiveGoalMS(
    playbackRate: Float
  ) -> Int64 {
    let goal = goalMS(isLive: true, playbackRate: playbackRate)
    return min(
      max(
        goal + refreshThresholdMS(for: goal),
        minimumNativeLiveGoalMS
      ),
      maximumGoalMS
    )
  }

  static let liveGoalMS: Int64 = 8_000
  static let minimumNativeLiveGoalMS: Int64 = 20_000
  static let videoOnDemandGoalMS: Int64 = 30_000
  static let maximumGoalMS: Int64 = 60_000
}
