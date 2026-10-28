import UIKit

// Full screen is the watch page itself: the window turns and the player grows in the same animation.
@MainActor
final class LiveNativeFullscreenPresenter {
  private weak var controller: LivePlayerController?
  private var orientationObservation: NSObjectProtocol?
  private var portraitExit: Task<Void, Never>?
  // A phone picked up off the table says "portrait" again, that's not someone leaving full screen.
  private var closesOnPortrait = false

  var isPageActive = false {
    didSet {
      guard oldValue != isPageActive else { return }
      isPageActive ? activate() : deactivate()
    }
  }

  var isPresenting: Bool { controller?.isPresentingFullscreen == true }

  var orientationMode: LiveOrientationLock.Mode {
    if isPresenting { return .landscape }
    return isPageActive ? .portrait : .free
  }

  init(controller: LivePlayerController) {
    self.controller = controller
  }

  func present() {
    present(facing: UIDevice.current.orientation)
  }

  func dismiss() {
    guard let controller else { return }
    closesOnPortrait = false
    cancelPortraitExit()
    // Idempotent: a landscape window with the full screen layout leaves
    // even when the flag is out of step with it.
    controller.isPresentingFullscreen = false
    if isPageActive {
      LiveOrientationLock.shared.refresh()
    } else {
      LiveOrientationLock.shared.release(by: self)
    }
  }

  private func activate() {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return }
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    orientationObservation = NotificationCenter.default.addObserver(
      forName: UIDevice.orientationDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.deviceDidRotate()
      }
    }
    LiveOrientationLock.shared.claim(by: self)
    if UIDevice.current.orientation.isLandscape {
      present(facing: UIDevice.current.orientation)
    }
  }

  private func deactivate() {
    guard let orientationObservation else { return }
    NotificationCenter.default.removeObserver(orientationObservation)
    self.orientationObservation = nil
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
    cancelPortraitExit()
    if isPresenting {
      dismiss()
    } else {
      LiveOrientationLock.shared.release(by: self)
    }
  }

  private func deviceDidRotate() {
    let orientation = UIDevice.current.orientation
    guard orientation == .portrait else {
      cancelPortraitExit()
      if orientation.isLandscape, !isPresenting {
        present(facing: orientation)
      } else if orientation.isLandscape {
        closesOnPortrait = true
      }
      return
    }
    guard isPresenting, closesOnPortrait, portraitExit == nil else { return }
    // Flipping from one landscape side to the other reads "portrait" for a moment on the way.
    portraitExit = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled else { return }
      self?.portraitExit = nil
      self?.dismiss()
    }
  }

  private func cancelPortraitExit() {
    portraitExit?.cancel()
    portraitExit = nil
  }

  private func present(facing orientation: UIDeviceOrientation) {
    guard let controller, !controller.isPresentingFullscreen, controller.nativePlayback != nil else { return }
    closesOnPortrait = orientation.isLandscape
    controller.isPresentingFullscreen = true
    // What is this piece of crap: phone turned left means interface landscape RIGHT. Thanks Apple.
    LiveOrientationLock.shared.claim(by: self, turningTo: orientation == .landscapeRight ? .landscapeLeft : .landscapeRight)
  }
}
