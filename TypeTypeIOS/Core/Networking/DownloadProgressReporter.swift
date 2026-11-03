import Foundation

struct DownloadProgress: Equatable, Sendable {
  let receivedBytes: Int64
  // Nil when the server sends no length: there is then no honest percentage, only a byte count.
  let expectedBytes: Int64?

  var fraction: Double? {
    guard let expectedBytes, expectedBytes > 0 else { return nil }
    return min(1, Double(receivedBytes) / Double(expectedBytes))
  }
}

// Task delegate for one download: redirects still go to the session delegate, which this does not implement.
// Reports the byte counts, not `fractionCompleted`: without a length that fraction is an estimate that creeps
// toward 100 % and sits at 99 % for most of the transfer. It is only used as the signal that bytes arrived.
final class DownloadProgressReporter: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  private static let unknownLengthStep: Int64 = 256 * 1_024

  private let report: @Sendable (DownloadProgress) -> Void
  private let lock = NSLock()
  private var observation: NSKeyValueObservation?
  private var reportedPercent = -1
  private var reportedBytes: Int64 = 0

  init(_ report: @escaping @Sendable (DownloadProgress) -> Void) {
    self.report = report
  }

  func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
    let observation = task.progress.observe(\.fractionCompleted) { [weak self, weak task] _, _ in
      guard let task else { return }
      self?.transferred(task.countOfBytesReceived, of: task.countOfBytesExpectedToReceive)
    }
    lock.withLock { self.observation = observation }
  }

  private func transferred(_ received: Int64, of expected: Int64) {
    let progress = DownloadProgress(receivedBytes: received, expectedBytes: expected > 0 ? expected : nil)
    let due = lock.withLock {
      if let fraction = progress.fraction {
        let percent = Int(fraction * 100)
        guard percent > reportedPercent else { return false }
        reportedPercent = percent
        return true
      }
      guard received - reportedBytes >= Self.unknownLengthStep else { return false }
      reportedBytes = received
      return true
    }
    if due {
      report(progress)
    }
  }
}
