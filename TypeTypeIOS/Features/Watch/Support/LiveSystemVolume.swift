import AVFoundation
import MediaPlayer
import SwiftUI

// iOS only lets an app change the device volume through the system volume slider. A nearly invisible MPVolumeView
// in the player also keeps the system volume HUD from covering the swipe ring; isHidden would disable both.
@MainActor
final class LiveSystemVolume: ObservableObject {
  fileprivate weak var slider: UISlider?

  var current: CGFloat {
    CGFloat(AVAudioSession.sharedInstance().outputVolume)
  }

  func set(_ fraction: CGFloat) {
    slider?.value = Float(min(max(fraction, 0), 1))
  }
}

struct LiveSystemVolumeView: UIViewRepresentable {
  let volume: LiveSystemVolume

  func makeUIView(context: Context) -> MPVolumeView {
    let view = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    view.alpha = 0.01
    view.isUserInteractionEnabled = false
    volume.slider = view.subviews.compactMap { $0 as? UISlider }.first
    return view
  }

  func updateUIView(_ view: MPVolumeView, context: Context) {
    if volume.slider == nil {
      volume.slider = view.subviews.compactMap { $0 as? UISlider }.first
    }
  }
}
