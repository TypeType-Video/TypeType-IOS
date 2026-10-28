import UIKit

/// Rotates with the player: full screen lands landscape, leaving it returns
/// to portrait. The app already lists both orientations in its Info.plist,
/// this only asks the scene to follow the player.
enum LiveScreenOrientation {
  static func set(_ orientation: UIInterfaceOrientationMask) {
    AppLogger.playback
      .info("fullscreen: orientation set \(String(describing: orientation), privacy: .public)")
    DispatchQueue.main.async {
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first
      else { return }
      // A request to the orientation the window already holds re-kicks the
      // rotation animation (the "doesn't stop, keeps moving" feel) — skip.
      if orientation == .portrait, scene.interfaceOrientation.isPortrait { return }
      if orientation == .landscape, scene.interfaceOrientation.isLandscape { return }
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
      scene.windows.first?.rootViewController?
        .setNeedsUpdateOfSupportedInterfaceOrientations()
    }
  }
}
