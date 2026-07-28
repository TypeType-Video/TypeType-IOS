import Combine
import SwiftUI
import UIKit

struct LiveDanmakuOverlay: UIViewRepresentable {
  let controller: LivePlayerController

  func makeUIView(context: Context) -> LiveDanmakuCanvasView {
    LiveDanmakuCanvasView(controller: controller)
  }

  func updateUIView(
    _ view: LiveDanmakuCanvasView,
    context: Context
  ) {
    view.update(controller: controller)
  }

  static func dismantleUIView(
    _ view: LiveDanmakuCanvasView,
    coordinator: Void
  ) {
    view.invalidate()
  }
}

@MainActor
final class LiveDanmakuCanvasView: UIView {
  static let labelPoolSize = 48

  weak var controller: LivePlayerController?
  var controllerObservation: AnyCancellable?
  var bulletCommentObservation: AnyCancellable?
  var displayLink: CADisplayLink?
  var labels: [UILabel] = []
  var labelAssignments: [Int: Int] = [:]
  var renderedSize = 1.0

  init(controller: LivePlayerController) {
    self.controller = nil
    super.init(frame: .zero)
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    accessibilityElementsHidden = true
    backgroundColor = .clear
    clipsToBounds = true
    installLabelPool()
    installDisplayLink()
    update(controller: controller)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func update(controller: LivePlayerController) {
    if self.controller !== controller {
      observeBulletComments(from: controller)
    }
    self.controller = controller
    refreshPresentation()
  }

  private func observeBulletComments(
    from controller: LivePlayerController
  ) {
    controllerObservation = controller.objectWillChange
      .sink { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.refreshPresentation()
        }
      }
    bulletCommentObservation = controller.bulletCommentStore.$state
      .sink { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.refreshPresentation()
        }
      }
  }

  private func refreshPresentation() {
    guard let controller else {
      isHidden = true
      displayLink?.isPaused = true
      resetRenderedComments()
      return
    }
    let shouldDisplay =
      controller.supportsBulletComments
        && controller.bulletCommentsEnabled
        && !controller.bulletComments.isEmpty
    isHidden = !shouldDisplay
    displayLink?.isPaused =
      !shouldDisplay || controller.state != .playing
    if !shouldDisplay {
      resetRenderedComments()
    }
  }

  func invalidate() {
    controllerObservation = nil
    bulletCommentObservation = nil
    displayLink?.invalidate()
    displayLink = nil
    resetRenderedComments()
  }

  func resetRenderedComments() {
    labelAssignments.removeAll(keepingCapacity: true)
    labels.forEach { $0.isHidden = true }
  }

  private func installLabelPool() {
    labels = (0..<Self.labelPoolSize).map { _ in
      let label = UILabel()
      label.isHidden = true
      label.isAccessibilityElement = false
      label.layer.shadowColor = UIColor.black.cgColor
      label.layer.shadowOpacity = 0.9
      label.layer.shadowRadius = 2
      label.layer.shadowOffset = CGSize(width: 1, height: 1)
      addSubview(label)
      return label
    }
  }

  private func installDisplayLink() {
    let link = CADisplayLink(
      target: self,
      selector: #selector(renderFrame)
    )
    link.preferredFrameRateRange = CAFrameRateRange(
      minimum: 60,
      maximum: 60,
      preferred: 60
    )
    link.add(to: .main, forMode: .common)
    displayLink = link
  }
}
