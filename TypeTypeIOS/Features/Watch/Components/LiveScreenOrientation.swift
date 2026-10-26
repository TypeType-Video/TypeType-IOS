import UIKit

/// Rotates with the player: full screen lands landscape, leaving it returns
/// to portrait. The app already lists both orientations in its Info.plist,
/// this only asks the scene to follow the player.
enum LiveScreenOrientation {
  static func set(_ orientation: UIInterfaceOrientationMask) {
    DispatchQueue.main.async {
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first
      else { return }
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }
}
