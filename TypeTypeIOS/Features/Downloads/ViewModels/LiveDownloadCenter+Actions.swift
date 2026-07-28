import Foundation

extension LiveDownloadCenter {
  @discardableResult
  func start(
    video: LiveVideoItem,
    options: LiveDownloadOptions
  ) async throws -> LiveManagedDownload {
    guard let scope = scopeProvider() else {
      throw LiveDownloadCenterError.missingScope
    }
    let job = try await service.create(
      videoURL: video.url,
      options: options
    )
    let now = Date()
    let record = LiveManagedDownload(
      id: UUID().uuidString,
      scope: scope,
      videoURL: video.url,
      title: video.title,
      options: options,
      createdAt: now,
      updatedAt: now,
      job: job,
      state: state(for: job),
      localFileName: nil,
      failureMessage: job.error
    )
    records.append(record)
    persist()
    if record.state.isActive {
      track(record.id)
    }
    return self.record(id: record.id) ?? record
  }

  func refresh() async {
    message = nil
    for record in visibleRecords {
      guard record.state.isActive
        || (
          record.job.status.lowercased() == "done"
            && artifactURL(for: record) == nil
        )
      else {
        continue
      }
      do {
        try await refreshRecord(record.id)
      } catch {
        message = Self.message(for: error)
      }
    }
  }

  func cancel(id: String) async throws {
    guard var record = record(id: id), record.state.canCancel else {
      return
    }
    trackingTasks[id]?.cancel()
    trackingTasks[id] = nil
    let job = try await service.cancel(id: record.job.id)
    record.job = job
    record.updatedAt = Date()
    record.state = state(for: job)
    if record.state.isActive {
      record.state = .cancelled
    }
    replace(record)
  }

  func retry(
    id: String,
    options: LiveDownloadOptions? = nil
  ) async throws {
    guard var record = record(id: id), record.state.canRetry else {
      return
    }
    if record.job.status.lowercased() == "done" {
      record.state = .saving
      record.failureMessage = nil
      record.updatedAt = Date()
      replace(record)
      track(id)
      return
    }
    let selection = options ?? record.options
    let job = try await service.create(
      videoURL: record.videoURL,
      options: selection
    )
    record.options = selection
    record.job = job
    record.state = state(for: job)
    record.failureMessage = nil
    record.localFileName = nil
    record.updatedAt = Date()
    replace(record)
    if record.state.isActive {
      track(id)
    }
  }

  func remove(id: String) async throws {
    guard let record = record(id: id), !record.state.isActive else {
      return
    }
    trackingTasks[id]?.cancel()
    trackingTasks[id] = nil
    if let localURL = artifactURL(for: record) {
      try? fileManager.removeItem(at: localURL)
    }
    try? await service.delete(id: record.job.id)
    records.removeAll { $0.id == id }
    persist()
  }
}
