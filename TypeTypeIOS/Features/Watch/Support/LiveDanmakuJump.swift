import Foundation

struct LiveDanmakuJump: Equatable {
  static let offerWindow: Int64 = 6000
  static let shortestJump: TimeInterval = 5

  let key: String
  let seconds: TimeInterval

  // Same patterns as the web client. Viewers also post the wall-clock time or date they watch at ("北京时间17:17",
  // "2024年03月07日09:20", "3.27 14:43"): those are not positions in the video.
  private static let clock = try? NSRegularExpression(pattern: #"(?<![\d:])(?:(\d{1,2}):)?([0-5]?\d):([0-5]\d)(?![\d:])"#)
  private static let wallClock = try? NSRegularExpression(pattern: #"[年月日号時]|时间|实时|今天|现在|打卡|凌晨|早上|上午|中午|下午|晚上|\d点|\d+\.\d+"#)

  static func seconds(in text: String) -> TimeInterval? {
    let range = NSRange(text.startIndex..., in: text)
    guard let clock, wallClock?.firstMatch(in: text, range: range) == nil,
      let match = clock.firstMatch(in: text, range: range)
    else { return nil }
    let part = { (index: Int) -> Double in
      Range(match.range(at: index), in: text).flatMap { Double(text[$0]) } ?? 0
    }
    return part(1) * 3600 + part(2) * 60 + part(3)
  }

  static func current(in comments: [LiveBulletComment], position: TimeInterval, duration: TimeInterval) -> LiveDanmakuJump? {
    guard duration > 0, duration.isFinite else { return nil }
    let positionMS = Int64(position * 1000)
    var latest: LiveDanmakuJump?
    var latestAt = Int64.min
    for (index, comment) in comments.enumerated() {
      let age = positionMS - comment.durationMilliseconds
      guard age >= 0, age < offerWindow, comment.durationMilliseconds > latestAt,
        let seconds = seconds(in: comment.text), seconds < duration, abs(seconds - position) >= shortestJump
      else { continue }
      latest = LiveDanmakuJump(key: "\(index):\(Int(seconds))", seconds: seconds)
      latestAt = comment.durationMilliseconds
    }
    return latest
  }
}
