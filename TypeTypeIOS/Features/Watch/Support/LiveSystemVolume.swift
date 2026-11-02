import AVFoundation
import MediaPlayer
import SwiftUI

// iOS only lets an app change the device volume through the system volume slider. A nearly invisible MPVolumeView
// in the player also keeps the system volume HUD from covering the swipe ring; isHidden would disable both.
// With the system HUD gone, the volume buttons would show nothing: their changes are published for the player ring.
@MainActor
final class LiveSystemVolume: ObservableObject {
  struct Change: Equatable {
    let fraction: CGFloat
    let id = UUID()
  }

  @Published private(set) var buttonChange: Change?
  fileprivate weak var slider: UISlider?
  private var observation: NSKeyValueObservation?
  private var lastSetAt = Date.distantPast

  init() {
    observation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] _, change in
      guard let value = change.newValue else { return }
      Task { @MainActor [weak self] in self?.outputVolumeChanged(CGFloat(value)) }
    }
  }

  var current: CGFloat {
    CGFloat(AVAudioSession.sharedInstance().outputVolume)
  }

  func set(_ fraction: CGFloat) {
    lastSetAt = Date()
    slider?.value = Float(min(max(fraction, 0), 1))
  }

  // The swipe's own slider writes come back through KVO a moment later; they are not button presses.
  private func outputVolumeChanged(_ fraction: CGFloat) {
    guard Date().timeIntervalSince(lastSetAt) > 0.4 else { return }
    buttonChange = Change(fraction: min(max(fraction, 0), 1))
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
