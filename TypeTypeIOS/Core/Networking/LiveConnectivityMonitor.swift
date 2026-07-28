import Combine
import Foundation
import Network

final class LiveConnectivityMonitor: ObservableObject {
  enum Status: Equatable {
    case checking
    case online
    case offline
  }

  @Published private(set) var status = Status.checking

  private let monitor: NWPathMonitor
  private let queue = DispatchQueue(
    label: "dev.typetype.ios.connectivity"
  )

  init(monitor: NWPathMonitor = NWPathMonitor()) {
    self.monitor = monitor
    monitor.pathUpdateHandler = { [weak self] path in
      let next: Status = path.status == .satisfied
        ? .online
        : .offline
      DispatchQueue.main.async {
        self?.status = next
      }
    }
    monitor.start(queue: queue)
  }

  deinit {
    monitor.cancel()
  }
}
