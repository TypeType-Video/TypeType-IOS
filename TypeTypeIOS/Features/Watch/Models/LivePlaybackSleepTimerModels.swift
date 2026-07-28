import Foundation

enum LivePlaybackSleepTimerMode: Equatable {
  case off
  case timed
  case endOfVideo
}

struct LivePlaybackSleepTimerState: Equatable {
  var mode: LivePlaybackSleepTimerMode = .off
  var duration: TimeInterval = 0
  var remaining: TimeInterval = 0

  var isActive: Bool {
    mode != .off
  }

  var summary: String {
    switch mode {
    case .off:
      return "Off"
    case .endOfVideo:
      return "End of video"
    case .timed:
      return Self.format(remaining)
    }
  }

  private static func format(_ interval: TimeInterval) -> String {
    let seconds = max(Int(interval.rounded(.up)), 0)
    let hours = seconds / 3_600
    let minutes = seconds % 3_600 / 60
    let remainingSeconds = seconds % 60
    if hours > 0 {
      return String(
        format: "%d:%02d:%02d remaining",
        hours,
        minutes,
        remainingSeconds
      )
    }
    return String(
      format: "%d:%02d remaining",
      minutes,
      remainingSeconds
    )
  }
}
