import UIKit

extension LiveDanmakuCanvasView {
  func visibleComments(
    at milliseconds: Double,
    controller: LivePlayerController
  ) -> [(index: Int, comment: LiveBulletComment)] {
    let maximumDuration = 6_000 / controller.bulletCommentSpeed
    let comments = controller.bulletComments
    let start = lowerBound(
      in: comments,
      value: Int64(milliseconds - maximumDuration)
    )
    let end = upperBound(
      in: comments,
      value: Int64(milliseconds)
    )
    return comments[start..<end].enumerated().compactMap {
      offset, comment in
      let index = start + offset
      guard comment.position != "BOTTOM" else { return nil }
      let elapsed =
        milliseconds - Double(comment.durationMilliseconds)
      let duration = comment.position == "REGULAR"
        ? maximumDuration
        : 3_000
      return elapsed >= 0 && elapsed < duration
        ? (index, comment)
        : nil
    }
  }

  private func lowerBound(
    in comments: [LiveBulletComment],
    value: Int64
  ) -> Int {
    var lower = 0
    var upper = comments.count
    while lower < upper {
      let middle = (lower + upper) / 2
      if comments[middle].durationMilliseconds < value {
        lower = middle + 1
      } else {
        upper = middle
      }
    }
    return lower
  }

  private func upperBound(
    in comments: [LiveBulletComment],
    value: Int64
  ) -> Int {
    var lower = 0
    var upper = comments.count
    while lower < upper {
      let middle = (lower + upper) / 2
      if comments[middle].durationMilliseconds <= value {
        lower = middle + 1
      } else {
        upper = middle
      }
    }
    return lower
  }

  func danmakuColor(_ argb: Int) -> UIColor {
    let rgb = UInt32(bitPattern: Int32(truncatingIfNeeded: argb))
      & 0x00FF_FFFF
    return UIColor(
      red: CGFloat((rgb >> 16) & 0xFF) / 255,
      green: CGFloat((rgb >> 8) & 0xFF) / 255,
      blue: CGFloat(rgb & 0xFF) / 255,
      alpha: 1
    )
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
