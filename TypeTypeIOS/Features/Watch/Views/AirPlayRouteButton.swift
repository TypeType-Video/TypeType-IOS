import AVKit
import SwiftUI

struct AirPlayRouteButton: UIViewRepresentable {
  func makeUIView(context: Context) -> AVRoutePickerView {
    let view = AVRoutePickerView()
    view.tintColor = .white
    view.activeTintColor = .white
    view.prioritizesVideoDevices = true
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentHuggingPriority(.required, for: .vertical)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .vertical)
    view.accessibilityLabel = "AirPlay"
    view.accessibilityIdentifier = "live.player.airplay"
    return view
  }

  func updateUIView(_ view: AVRoutePickerView, context: Context) {}
}
