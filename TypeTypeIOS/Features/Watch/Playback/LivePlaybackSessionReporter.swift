import Foundation

@MainActor
final class LivePlaybackSessionReporter {
  private typealias Operation = (
    LivePlaybackSessionReporter
  ) async -> Void

  private let service: LiveSessionActivityServiceProtocol
  private var operationTask: Task<Void, Never>?
  private var wantsActiveSession = false
  private var hasActiveSession = false
  private var startQueued = false

  init(service: LiveSessionActivityServiceProtocol) {
    self.service = service
  }

  func startIfNeeded(_ snapshot: LivePlaybackActivitySnapshot) {
    wantsActiveSession = true
    guard !hasActiveSession, !startQueued else { return }
    startQueued = true
    enqueue { reporter in
      reporter.startQueued = false
      guard reporter.wantsActiveSession,
        !reporter.hasActiveSession
      else {
        return
      }
      do {
        try await reporter.service.reportPlaybackStart(snapshot)
        reporter.hasActiveSession = true
        if !reporter.wantsActiveSession {
          try? await reporter.service.reportPlaybackStop()
          reporter.hasActiveSession = false
        }
      } catch {
        reporter.hasActiveSession = false
      }
    }
  }

  func progress(_ snapshot: LivePlaybackActivitySnapshot) {
    enqueue { reporter in
      guard reporter.wantsActiveSession,
        reporter.hasActiveSession
      else {
        return
      }
      try? await reporter.service.reportPlaybackProgress(snapshot)
    }
  }

  func stop() {
    wantsActiveSession = false
    enqueue { reporter in
      guard reporter.hasActiveSession else { return }
      reporter.hasActiveSession = false
      try? await reporter.service.reportPlaybackStop()
    }
  }

  func waitForPendingOperations() async {
    _ = await operationTask?.result
  }

  private func enqueue(_ operation: @escaping Operation) {
    let previous = operationTask
    operationTask = Task { @MainActor [weak self] in
      _ = await previous?.result
      guard let self else { return }
      await operation(self)
    }
  }
}
