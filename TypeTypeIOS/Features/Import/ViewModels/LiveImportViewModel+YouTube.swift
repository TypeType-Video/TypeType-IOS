import Foundation

@MainActor
extension LiveImportViewModel {
  func startYouTubeQueue() async {
    guard canStartYouTubeQueue else { return }
    isRunning = true
    errorMessage = nil
    defer {
      activeYouTubeArchiveID = nil
      isRunning = false
    }

    for archiveID in pendingYouTubeArchiveIDs {
      do {
        try Task.checkCancellation()
        activeYouTubeArchiveID = archiveID
        try await importYouTubeArchive(id: archiveID)
      } catch is CancellationError {
        return
      } catch {
        let message = Self.message(for: error)
        updateArchive(id: archiveID) {
          $0.state = .failed(message)
        }
        errorMessage = message
        return
      }
    }
  }

  private var pendingYouTubeArchiveIDs: [UUID] {
    youTubeArchives.compactMap { archive in
      switch archive.state {
      case .queued, .failed:
        return archive.id
      default:
        return nil
      }
    }
  }

  private func importYouTubeArchive(id: UUID) async throws {
    guard let archive = youTubeArchives.first(where: { $0.id == id })
    else { return }
    beginUpload(id: id)

    var job = try await service.createYouTubeImport(
      fileURL: archive.url,
      fileName: archive.fileName
    )
    updateArchive(id: id) {
      $0.job = job
      $0.progress = max(5, min(job.progress, 10))
      $0.state = .previewing
    }

    let preview = try await service.youTubePreview(id: job.jobID)
    updateArchive(id: id) {
      $0.preview = preview
      $0.progress = 12
      $0.state = .committing
    }

    job = try await service.commitYouTube(
      id: job.jobID,
      options: LiveYouTubeImportCommit()
    )
    updateArchive(id: id) {
      $0.job = job
      $0.progress = max(15, job.progress)
      $0.state = .importing
    }
    try await pollYouTubeJob(&job, archiveID: id)
    guard job.status == "completed" else {
      throw LiveImportError.failed(
        job.error ?? "YouTube import failed."
      )
    }
    try await finishYouTubeImport(job: job, archiveID: id)
  }

  private func beginUpload(id: UUID) {
    updateArchive(id: id) {
      $0.state = .uploading
      $0.progress = 2
      $0.job = nil
      $0.preview = nil
      $0.report = nil
    }
  }

  private func pollYouTubeJob(
    _ job: inout LiveYouTubeImportJob,
    archiveID: UUID
  ) async throws {
    while job.status == "pending" || job.status == "running" {
      try Task.checkCancellation()
      try await Task.sleep(for: .seconds(1))
      job = try await service.youTubeJob(id: job.jobID)
      let currentJob = job
      updateArchive(id: archiveID) {
        $0.job = currentJob
        $0.progress = max(15, min(currentJob.progress, 99))
        $0.state = .importing
      }
    }
  }

  private func finishYouTubeImport(
    job: LiveYouTubeImportJob,
    archiveID: UUID
  ) async throws {
    let report = try await youTubeReportWithRetry(id: job.jobID)
    updateArchive(id: archiveID) {
      $0.job = job
      $0.report = report
      $0.progress = 100
      $0.state = .completed
    }
  }

  private func youTubeReportWithRetry(
    id: String
  ) async throws -> LiveYouTubeImportReport {
    for attempt in 0...5 {
      do {
        return try await service.youTubeReport(id: id)
      } catch let error as NetworkError {
        guard case .statusCode(429, _) = error, attempt < 5 else {
          throw error
        }
        try await Task.sleep(
          for: .milliseconds(1_200 * (attempt + 1))
        )
      }
    }
    throw LiveImportError.failed("Unable to load the import report.")
  }

  private func updateArchive(
    id: UUID,
    mutation: (inout LiveYouTubeImportArchive) -> Void
  ) {
    guard let index = youTubeArchives.firstIndex(
      where: { $0.id == id }
    ) else { return }
    mutation(&youTubeArchives[index])
  }
}

private enum LiveImportError: LocalizedError {
  case failed(String)

  var errorDescription: String? {
    switch self {
    case let .failed(message): return message
    }
  }
}
