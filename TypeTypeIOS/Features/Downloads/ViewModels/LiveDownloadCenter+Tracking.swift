import Foundation

extension LiveDownloadCenter {
  func track(_ id: String) {
    guard trackingTasks[id] == nil else { return }
    trackingTasks[id] = Task { [weak self] in
      var failureCount = 0
      while !Task.isCancelled {
        guard let self, let record = self.record(id: id),
          record.state.isActive,
          record.scope == self.scopeProvider()
        else {
          break
        }
        do {
          let attempt = failureCount + 1
          guard let delay = self.retryPolicy.delayBeforeAttempt(attempt) else {
            break
          }
          try await Task.sleep(for: delay)
          try await self.refreshRecord(id)
          failureCount = 0
        } catch is CancellationError {
          break
        } catch {
          failureCount += 1
          let isTransient = Self.isTransientNetworkFailure(error)
          if !isTransient
            || failureCount >= self.retryPolicy.maxAttempts {
            self.markFailedAfterRetries(
              id: id,
              error: error,
              transient: isTransient
            )
            break
          }
          if isTransient {
            self.markWaitingForNetwork(id: id)
          }
          AppLogger.network.error(
            "Download refresh failed: \(Self.message(for: error), privacy: .public)"
          )
        }
      }
      self?.trackingTasks[id] = nil
    }
  }

  func refreshRecord(_ id: String) async throws {
    guard refreshingRecordIDs.insert(id).inserted else { return }
    defer { refreshingRecordIDs.remove(id) }
    guard var record = record(id: id),
      record.scope == scopeProvider()
    else {
      return
    }
    let job = try await service.job(id: record.job.id)
    guard record.scope == scopeProvider() else { return }
    let wasSaving = record.state == .saving
    record.job = job
    record.state = state(for: job)
    if !(wasSaving && record.state == .saving) {
      record.failureMessage = job.error
    }
    record.updatedAt = Date()
    replace(record)
    if record.state == .saving {
      try await saveArtifact(for: id)
    }
  }

  func markWaitingForNetwork(id: String) {
    guard var record = record(id: id), record.state.isActive else {
      return
    }
    record.failureMessage = String(localized: "Waiting for the network. This download will resume automatically.")
    record.updatedAt = Date()
    replace(record)
  }

  static func isTransientNetworkFailure(
    _ error: Error
  ) -> Bool {
    if error is DownloadInterruption { return true }
    guard let networkError = error as? NetworkError else {
      return false
    }
    switch networkError {
    case .transport:
      return true
    case let .statusCode(code, _):
      return [408, 425, 429, 500, 502, 503, 504]
        .contains(code)
    default:
      return false
    }
  }

  static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? error.localizedDescription
  }

  private func markFailedAfterRetries(
    id: String,
    error: Error,
    transient: Bool
  ) {
    guard var record = record(id: id), record.state.isActive else {
      return
    }
    record.state = .failed
    savingProgress[id] = nil
    record.failureMessage = transient
      ? String(localized: "Download paused after \(retryPolicy.maxAttempts) attempts. The network is unavailable; try again later.")
      : String(localized: "Download failed.") + " " + Self.message(for: error)
    record.updatedAt = Date()
    replace(record)
  }
}
