import AVFoundation
import UIKit

// Each pan begins only on its own start zone and direction, and those rules exclude each other: once one owns a
// touch, the others have already failed, whatever the finger does next.
@MainActor
final class LivePlayerSurfaceGestures: NSObject, UIGestureRecognizerDelegate {
  weak var controller: LivePlayerController?
  var swipeHandler: ((PlayerSwipeAdjustmentEvent) -> Void)?
  var horizontalSeekHandler: ((PlayerHorizontalSeekEvent) -> Void)?
  var fullscreenExitHandler: (() -> Void)?
  private weak var swipeRecognizer: UIPanGestureRecognizer?
  private weak var seekRecognizer: UIPanGestureRecognizer?
  private weak var exitRecognizer: UIPanGestureRecognizer?
  private var swipeKind: PlayerSwipeAdjustmentKind?
  private var swipeBaseFraction: CGFloat = 0.5
  private var seekBasePosition: TimeInterval = 0
  private var timelineSeek: PlayerTimelineSeekGesture?
  private var timelineSeekLastX: CGFloat = 0
  private var exitTouchDown: TimeInterval = 0
  private let seekHaptics = UISelectionFeedbackGenerator()
  private let exitHaptics = UIImpactFeedbackGenerator(style: .light)

  init(controller: LivePlayerController) {
    self.controller = controller
    super.init()
  }

  func install(in view: UIView) {
    swipeRecognizer = addPan(to: view, action: #selector(handleSwipe(_:)))
    seekRecognizer = addPan(to: view, action: #selector(handleHorizontalSeek(_:)))
    exitRecognizer = addPan(to: view, action: #selector(handleFullscreenExit(_:)))
  }

  private func addPan(to view: UIView, action: Selector) -> UIPanGestureRecognizer {
    let recognizer = UIPanGestureRecognizer(target: self, action: action)
    recognizer.cancelsTouchesInView = false
    recognizer.delegate = self
    view.addGestureRecognizer(recognizer)
    return recognizer
  }

  @objc private func handleHorizontalSeek(_ recognizer: UIPanGestureRecognizer) {
    guard let view = recognizer.view, view.bounds.width > 0, let duration = controller?.duration, duration > 0
    else { return }
    let translation = recognizer.translation(in: view)
    switch recognizer.state {
    case .began:
      timelineSeek = PlayerTimelineSeekGesture(start: seekBasePosition, duration: duration, width: view.bounds.width)
      timelineSeekLastX = translation.x
      seekHaptics.selectionChanged()
      horizontalSeekHandler?(.began(position: seekBasePosition))
    case .changed:
      guard var seek = timelineSeek else { return }
      let wasFine = seek.isFine
      let position = seek.move(deltaX: translation.x - timelineSeekLastX, downwardTravel: translation.y)
      timelineSeekLastX = translation.x
      timelineSeek = seek
      if seek.isFine != wasFine { seekHaptics.selectionChanged() }
      horizontalSeekHandler?(.updated(position: position, isFine: seek.isFine))
    case .ended, .cancelled, .failed:
      horizontalSeekHandler?(.ended(position: timelineSeek?.position ?? seekBasePosition))
      timelineSeek = nil
      seekBasePosition = controller?.position ?? seekBasePosition
    default:
      break
    }
  }

  @objc private func handleSwipe(_ recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
      guard let kind = swipeKind else { return }
      swipeHandler?(.began(kind: kind, fraction: swipeBaseFraction))
    case .changed:
      guard let kind = swipeKind, let view = recognizer.view else { return }
      let fraction = PlayerSwipeAdjustmentRules.fraction(
        base: swipeBaseFraction,
        translationHeight: recognizer.translation(in: view).y,
        height: view.bounds.height
      )
      swipeHandler?(.updated(kind: kind, fraction: fraction))
    case .ended, .cancelled, .failed:
      swipeKind = nil
      swipeHandler?(.ended)
    default:
      break
    }
  }

  @objc private func handleFullscreenExit(_ recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
      exitHaptics.impactOccurred()
    case .ended:
      guard let view = recognizer.view,
        PlayerFullscreenExitRules.completes(translationHeight: recognizer.translation(in: view).y)
      else { return }
      fullscreenExitHandler?()
    default:
      break
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === exitRecognizer { exitTouchDown = touch.timestamp }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer,
      let view = recognizer.view,
      let controller,
      view.bounds.width > 0,
      view.bounds.height > 0
    else { return false }
    let location = recognizer.location(in: view)
    let moved = recognizer.translation(in: view)
    let translation = CGSize(width: moved.x, height: moved.y)
    let start = CGPoint(x: location.x - moved.x, y: location.y - moved.y)
    let preferences = controller.appPreferences.preferences

    if recognizer === exitRecognizer {
      guard fullscreenExitHandler != nil else { return false }
      let held = ProcessInfo.processInfo.systemUptime - exitTouchDown
      if preferences.playerLongPressSpeedEnabled, held >= PlayerFullscreenExitRules.speedRampHold { return false }
      return PlayerFullscreenExitRules.canBegin(startLocation: start, size: view.bounds.size, translation: translation)
    }
    if recognizer === seekRecognizer {
      // Direction only: the pan begins after about 10 pt, so a distance gate would fail every scrub.
      guard horizontalSeekHandler != nil,
        abs(translation.width) > abs(translation.height) * 1.25,
        preferences.playerSwipeSeekEnabled,
        !preferences.usesAccessiblePlayerControls(),
        controller.duration > 0
      else { return false }
      seekBasePosition = controller.position
      return true
    }
    guard recognizer === swipeRecognizer, swipeHandler != nil,
      let kind = PlayerSwipeAdjustmentRules.kind(startLocation: start, size: view.bounds.size, translation: translation)
    else { return false }
    swipeKind = kind
    swipeBaseFraction = switch kind {
    case .brightness: CGFloat(UIScreen.main.brightness)
    case .volume: CGFloat(AVAudioSession.sharedInstance().outputVolume)
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}
