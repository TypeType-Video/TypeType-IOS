import CoreGraphics
import Foundation

// Same scrub as the Android player: the whole video spans the view width; dragging 48 pt down switches to fine
// seeking (ten times finer, at most 0.1 s per point) until the finger comes back above 32 pt.
struct PlayerTimelineSeekGesture {
  private(set) var position: TimeInterval
  private(set) var isFine = false
  private let duration: TimeInterval
  private let width: CGFloat

  init(start: TimeInterval, duration: TimeInterval, width: CGFloat) {
    self.duration = max(duration, 0)
    self.width = width
    position = min(max(start, 0), self.duration)
  }

  mutating func move(deltaX: CGFloat, downwardTravel: CGFloat) -> TimeInterval {
    guard duration > 0, width > 0, deltaX.isFinite, downwardTravel.isFinite else { return position }
    if downwardTravel >= 48 {
      isFine = true
    } else if downwardTravel <= 32 {
      isFine = false
    }
    let normal = duration / Double(width)
    let perPoint = isFine ? min(normal / 10, 0.1) : normal
    position = min(max(position + Double(deltaX) * perPoint, 0), duration)
    return position
  }
}
