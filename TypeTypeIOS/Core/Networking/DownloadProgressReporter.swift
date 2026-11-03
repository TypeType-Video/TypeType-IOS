import Foundation

// Task delegate for one download: redirects still go to the session delegate, which this does not implement.
final class DownloadProgressReporter: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  private let report: @Sendable (Double) -> Void
  private let lock = NSLock()
  private var observation: NSKeyValueObservation?
  private var reportedPercent = -1

  init(_ report: @escaping @Sendable (Double) -> Void) {
    self.report = report
  }

  func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
    let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
      self?.progressChanged(progress)
    }
    lock.withLock { self.observation = observation }
  }

  private func progressChanged(_ progress: Progress) {
    guard progress.totalUnitCount > 0 else { return }
    let percent = min(100, Int(progress.fractionCompleted * 100))
    let advanced = lock.withLock {
      guard percent > reportedPercent else { return false }
      reportedPercent = percent
      return true
    }
    if advanced {
      report(Double(percent) / 100)
    }
  }
}
