import UIKit

enum LiveScreenOrientation {
  static func set(_ orientation: UIInterfaceOrientationMask) {
    AppLogger.playback
      .info("fullscreen: orientation set \(String(describing: orientation), privacy: .public)")
    DispatchQueue.main.async {
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first
      else { return }
      // Asking for the orientation the window already has restarts the rotation animation.
      if orientation == .portrait, scene.interfaceOrientation.isPortrait { return }
      if orientation == .landscape, scene.interfaceOrientation.isLandscape { return }
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
      scene.windows.first?.rootViewController?
        .setNeedsUpdateOfSupportedInterfaceOrientations()
    }
  }
}
