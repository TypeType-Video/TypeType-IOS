import Foundation

final class ContinuationGate: @unchecked Sendable {
  private let lock = NSLock()
  private var didResume = false

  func resume<T>(
    _ continuation: CheckedContinuation<T, Error>,
    returning value: T
  ) {
    guard lock.withLock({
      guard !didResume else { return false }
      didResume = true
      return true
    }) else {
      return
    }
    continuation.resume(returning: value)
  }

  func resume<T>(
    _ continuation: CheckedContinuation<T, Error>,
    throwing error: Error
  ) {
    guard lock.withLock({
      guard !didResume else { return false }
      didResume = true
      return true
    }) else {
      return
    }
    continuation.resume(throwing: error)
  }
}
