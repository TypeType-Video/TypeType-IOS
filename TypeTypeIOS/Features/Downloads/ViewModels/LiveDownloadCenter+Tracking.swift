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
          let exponent = min(failureCount, 4)
          let delay = 1_500 * (1 << exponent)
          try await Task.sleep(for: .milliseconds(delay))
          try await self.refreshRecord(id)
          failureCount = 0
        } catch is CancellationError {
          break
        } catch {
          failureCount += 1
          if Self.isTransientNetworkFailure(error) {
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
    record.job = job
    record.state = state(for: job)
    record.failureMessage = job.error
    record.updatedAt = Date()
    replace(record)
    if record.state == .saving {
      await saveArtifact(for: id)
    }
  }

  func markWaitingForNetwork(id: String) {
    guard var record = record(id: id), record.state.isActive else {
      return
    }
    record.failureMessage =
      "Waiting for the network. This download will resume automatically."
    record.updatedAt = Date()
    replace(record)
  }

  static func isTransientNetworkFailure(
    _ error: Error
  ) -> Bool {
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
}
