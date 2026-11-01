import AVKit
import SwiftUI

struct AirPlayRouteButton: UIViewRepresentable {
  var onPresentingChange: ((Bool) -> Void)?

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> AVRoutePickerView {
    let view = AVRoutePickerView()
    view.delegate = context.coordinator
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

  func updateUIView(_ view: AVRoutePickerView, context: Context) {
    context.coordinator.onPresentingChange = onPresentingChange
  }

  final class Coordinator: NSObject, AVRoutePickerViewDelegate {
    var onPresentingChange: ((Bool) -> Void)?

    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
      onPresentingChange?(true)
    }

    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
      onPresentingChange?(false)
    }
  }
}
