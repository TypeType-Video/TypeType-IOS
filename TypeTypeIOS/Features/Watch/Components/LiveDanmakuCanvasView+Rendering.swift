import UIKit

extension LiveDanmakuCanvasView {
  @objc func renderFrame() {
    guard bounds.width > 0, bounds.height > 0,
      let controller
    else {
      return
    }

    let milliseconds = controller.precisePosition * 1_000
    let avoidsSponsorBanner =
      controller.sponsorBlockShowCurrentSegment
        && controller.activeSponsorBlockWindow(
          at: controller.precisePosition
        ) != nil
    let topInset = avoidsSponsorBanner
      ? min(64, bounds.height * 0.3)
      : 0
    let laneCount = avoidsSponsorBanner ? 6 : 8
    let comments = visibleComments(
      at: milliseconds,
      controller: controller
    ).prefix(Self.labelPoolSize)
    let visibleIndices = Set(comments.map(\.index))

    let staleIndices = labelAssignments.keys.filter {
      !visibleIndices.contains($0)
    }
    for index in staleIndices {
      guard let labelIndex = labelAssignments.removeValue(
        forKey: index
      ) else {
        continue
      }
      labels[labelIndex].isHidden = true
    }

    if renderedSize != controller.bulletCommentSize {
      renderedSize = controller.bulletCommentSize
      for (commentIndex, labelIndex) in labelAssignments {
        guard let comment = controller.bulletComments[
          safe: commentIndex
        ] else {
          continue
        }
        configure(
          labels[labelIndex],
          comment: comment,
          sizeMultiplier: renderedSize
        )
      }
    }

    for item in comments {
      guard let label = label(
        for: item.index,
        comment: item.comment,
        sizeMultiplier: controller.bulletCommentSize
      ) else {
        continue
      }
      position(
        label,
        comment: item.comment,
        index: item.index,
        milliseconds: milliseconds,
        topInset: topInset,
        laneCount: laneCount,
        speed: controller.bulletCommentSpeed
      )
    }
  }

  private func label(
    for index: Int,
    comment: LiveBulletComment,
    sizeMultiplier: Double
  ) -> UILabel? {
    if let labelIndex = labelAssignments[index] {
      return labels[labelIndex]
    }

    let occupiedIndices = Set(labelAssignments.values)
    guard let labelIndex = labels.indices.first(where: {
      !occupiedIndices.contains($0)
    }) else {
      return nil
    }
    let label = labels[labelIndex]
    labelAssignments[index] = labelIndex
    configure(
      label,
      comment: comment,
      sizeMultiplier: sizeMultiplier
    )
    label.isHidden = false
    return label
  }

  private func configure(
    _ label: UILabel,
    comment: LiveBulletComment,
    sizeMultiplier: Double
  ) {
    let fontSize = CGFloat(max(
      10,
      20 * comment.relativeFontSize * sizeMultiplier
    ))
    label.text = comment.text
    label.font = .systemFont(ofSize: fontSize, weight: .bold)
    label.textColor = danmakuColor(comment.argbColor)
    label.sizeToFit()
  }

  private func position(
    _ label: UILabel,
    comment: LiveBulletComment,
    index: Int,
    milliseconds: Double,
    topInset: CGFloat,
    laneCount: Int,
    speed: Double
  ) {
    let availableHeight = max(bounds.height - topInset, 1)
    let laneHeight = min(
      max(availableHeight / CGFloat(laneCount), 22),
      36
    )
    let elapsed =
      milliseconds - Double(comment.durationMilliseconds)

    if comment.position == "REGULAR" {
      let duration = 6_000 / speed
      let progress = min(max(elapsed / duration, 0), 1)
      let start = bounds.width + label.bounds.width / 2
      let end = -label.bounds.width / 2
      label.center = CGPoint(
        x: start + (end - start) * progress,
        y: topInset + 14 + CGFloat(index % laneCount) * laneHeight
      )
    } else {
      label.center = CGPoint(
        x: bounds.midX,
        y: topInset + 14 + CGFloat(index % 3) * laneHeight
      )
    }
  }
}
