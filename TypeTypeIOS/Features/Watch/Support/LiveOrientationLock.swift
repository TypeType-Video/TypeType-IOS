import UIKit

@MainActor
final class LiveOrientationLock {
  enum Mode {
    case free
    case portrait
    case landscape
  }

  private weak var owner: LiveNativeFullscreenPresenter?

  var mask: UIInterfaceOrientationMask {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return .all }
    switch owner?.orientationMode ?? .free {
    case .free: return .allButUpsideDown
    case .portrait: return .portrait
    case .landscape: return .landscape
    }
  }

  func claim(by presenter: LiveNativeFullscreenPresenter, turningTo orientation: UIInterfaceOrientation? = nil) {
    owner = presenter
    refresh(turningTo: orientation)
  }

  func release(by presenter: LiveNativeFullscreenPresenter) {
    guard owner === presenter else { return }
    owner = nil
    refresh()
  }

  func refresh(turningTo orientation: UIInterfaceOrientation? = nil) {
    guard let scene = LiveWindowScene.active else { return }
    var controller = scene.keyWindow?.rootViewController
    while let current = controller {
      current.setNeedsUpdateOfSupportedInterfaceOrientations()
      controller = current.presentedViewController
    }
    let mask = mask
    let target: UIInterfaceOrientationMask? = switch orientation {
    case .landscapeLeft: .landscapeLeft
    case .landscapeRight: .landscapeRight
    case .portrait: .portrait
    default: nil
    }
    if let target, mask.contains(target), scene.interfaceOrientation != orientation {
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: target))
      return
    }
    let current: UIInterfaceOrientationMask = scene.interfaceOrientation.isLandscape ? .landscape : .portrait
    if mask.intersection(current).isEmpty {
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    }
  }
}

enum LiveWindowScene {
  @MainActor static var active: UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
  }
}
