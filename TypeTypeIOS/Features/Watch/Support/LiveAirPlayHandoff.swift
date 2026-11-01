import Combine
import Foundation

@MainActor
final class LiveAirPlayHandoff {
  enum Phase {
    case off
    case active
    case refused
  }

  var phase = Phase.off
  var watchdog: Task<Void, Never>?
  var routeObservation: AnyCancellable?

  var isActive: Bool { phase == .active }
}
