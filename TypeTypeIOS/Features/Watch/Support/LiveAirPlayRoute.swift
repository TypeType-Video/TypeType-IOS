import AVFoundation
import Foundation

@MainActor
final class LiveAirPlayRoute: ObservableObject {
  @Published private(set) var deviceName: String?
  private var observation: NSObjectProtocol?

  init() {
    refresh()
    observation = NotificationCenter.default.addObserver(
      forName: AVAudioSession.routeChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.refresh() }
    }
  }

  deinit {
    if let observation { NotificationCenter.default.removeObserver(observation) }
  }

  private func refresh() {
    let output = AVAudioSession.sharedInstance().currentRoute.outputs.first { $0.portType == .airPlay }
    if deviceName != output?.portName { deviceName = output?.portName }
  }
}
