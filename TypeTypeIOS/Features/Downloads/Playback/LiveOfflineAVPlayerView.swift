import AVKit
import SwiftUI

struct LiveOfflineAVPlayerView: UIViewControllerRepresentable {
  let player: AVPlayer

  func makeUIViewController(
    context: Context
  ) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = true
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.videoGravity = .resizeAspect
    return controller
  }

  func updateUIViewController(
    _ controller: AVPlayerViewController,
    context: Context
  ) {
    if controller.player !== player {
      controller.player = player
    }
  }
}
