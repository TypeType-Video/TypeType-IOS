import AVKit
import SwiftUI

/// The system route picker: unlike a custom button it opens the real AirPlay sheet and routes
/// AVPlayer through the system.
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
