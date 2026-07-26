import AVKit
import SwiftUI

struct DemoPlayerLayerView: UIViewControllerRepresentable {
  let player: AVPlayer

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = true
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.entersFullScreenWhenPlaybackBegins = false
    controller.exitsFullScreenWhenPlaybackEnds = false
    controller.videoGravity = .resizeAspect
    controller.view.backgroundColor = .black
    return controller
  }

  func updateUIViewController(
    _ uiViewController: AVPlayerViewController,
    context: Context
  ) {
    if uiViewController.player !== player {
      uiViewController.player = player
    }
  }
}
