import Foundation

@MainActor
final class LiveImportViewModel: ObservableObject {
  @Published private(set) var isRunning = false
  @Published private(set) var pipePipeResult: LivePipePipeRestoreResult?
  @Published private(set) var youTubeJob: LiveYouTubeImportJob?
  @Published private(set) var youTubePreview: LiveYouTubeImportPreview?
  @Published private(set) var youTubeReport: LiveYouTubeImportReport?
  @Published private(set) var errorMessage: String?

  private let service: LiveImportServiceProtocol

  init(service: LiveImportServiceProtocol) {
    self.service = service
  }

  func restorePipePipe(url: URL, timeMode: String) async {
    await run {
      let file = try Self.read(url)
      pipePipeResult = try await service.restorePipePipe(
        data: file.data,
        fileName: file.name,
        timeMode: timeMode
      )
    }
  }

  func importYouTube(url: URL) async {
    await run {
      let file = try Self.read(url)
      var job = try await service.createYouTubeImport(
        data: file.data,
        fileName: file.name
      )
      youTubeJob = job
      youTubePreview = try await service.youTubePreview(id: job.jobID)
      job = try await service.commitYouTube(
        id: job.jobID,
        options: LiveYouTubeImportCommit()
      )
      youTubeJob = job
      while job.status == "pending" || job.status == "running" {
        try Task.checkCancellation()
        try await Task.sleep(for: .seconds(1))
        job = try await service.youTubeJob(id: job.jobID)
        youTubeJob = job
      }
      guard job.status == "completed" else {
        throw LiveImportError.failed(
          job.error ?? "YouTube import failed."
        )
      }
      youTubeReport = try await service.youTubeReport(id: job.jobID)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func run(_ operation: () async throws -> Void) async {
    guard !isRunning else { return }
    isRunning = true
    errorMessage = nil
    defer { isRunning = false }
    do {
      try await operation()
    } catch is CancellationError {
      return
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription
        ?? "The import could not be completed."
    }
  }

  nonisolated private static func read(
    _ url: URL
  ) throws -> (data: Data, name: String) {
    let granted = url.startAccessingSecurityScopedResource()
    defer {
      if granted {
        url.stopAccessingSecurityScopedResource()
      }
    }
    return (try Data(contentsOf: url), url.lastPathComponent)
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
