import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveImportViewModelTests: XCTestCase {
  func testYouTubeQueueDeduplicatesAndProcessesArchivesInOrder() async throws {
    let service = ImportServiceStub()
    let viewModel = LiveImportViewModel(service: service)
    let first = try archive(named: "takeout-1.zip")
    let second = try archive(named: "takeout-2.zip")
    defer {
      try? FileManager.default.removeItem(
        at: first.deletingLastPathComponent()
      )
      try? FileManager.default.removeItem(
        at: second.deletingLastPathComponent()
      )
    }

    viewModel.queueYouTube(urls: [first, first, second])
    XCTAssertEqual(viewModel.youTubeArchives.map(\.fileName), [
      "takeout-1.zip",
      "takeout-2.zip",
    ])

    await viewModel.startYouTubeQueue()

    XCTAssertEqual(viewModel.completedYouTubeArchiveCount, 2)
    XCTAssertEqual(viewModel.youTubeOverallProgress, 1)
    XCTAssertEqual(service.createdFileNames, [
      "takeout-1.zip",
      "takeout-2.zip",
    ])
    XCTAssertTrue(
      viewModel.youTubeArchives.allSatisfy {
        if case .completed = $0.state { return true }
        return false
      }
    )
  }

  func testYouTubeQueueRetriesRateLimitedReport() async throws {
    let service = ImportServiceStub()
    service.remainingReportFailures = 2
    let viewModel = LiveImportViewModel(service: service)
    let file = try archive(named: "takeout.zip")
    defer {
      try? FileManager.default.removeItem(
        at: file.deletingLastPathComponent()
      )
    }

    viewModel.queueYouTube(urls: [file])
    await viewModel.startYouTubeQueue()

    XCTAssertEqual(service.reportRequestCount, 3)
    XCTAssertEqual(viewModel.completedYouTubeArchiveCount, 1)
    XCTAssertNil(viewModel.errorMessage)
  }

  private func archive(named name: String) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: false
    )
    let url = directory.appendingPathComponent(name)
    try Data(name.utf8).write(to: url)
    return url
  }
}

private final class ImportServiceStub: LiveImportServiceProtocol {
  var createdFileNames: [String] = []
  var remainingReportFailures = 0
  var reportRequestCount = 0

  func restorePipePipe(
    data: Data,
    fileName: String,
    timeMode: String
  ) async throws -> LivePipePipeRestoreResult {
    throw NetworkError.invalidResponse
  }

  func createYouTubeImport(
    fileURL: URL,
    fileName: String
  ) async throws -> LiveYouTubeImportJob {
    createdFileNames.append(fileName)
    return job(
      id: "\(createdFileNames.count)",
      status: "pending",
      phase: "preview",
      progress: 5
    )
  }

  func youTubeJob(id: String) async throws -> LiveYouTubeImportJob {
    job(id: id, status: "completed", phase: "completed", progress: 100)
  }

  func youTubePreview(
    id: String
  ) async throws -> LiveYouTubeImportPreview {
    LiveYouTubeImportPreview(
      counts: counts,
      dedup: counts,
      warnings: [],
      errors: []
    )
  }

  func commitYouTube(
    id: String,
    options: LiveYouTubeImportCommit
  ) async throws -> LiveYouTubeImportJob {
    job(id: id, status: "completed", phase: "completed", progress: 100)
  }

  func youTubeReport(
    id: String
  ) async throws -> LiveYouTubeImportReport {
    reportRequestCount += 1
    if remainingReportFailures > 0 {
      remainingReportFailures -= 1
      throw NetworkError.statusCode(429, "Please retry")
    }
    let stats = LiveYouTubeImportStats(
      imported: 1,
      skipped: 0,
      failed: 0
    )
    return LiveYouTubeImportReport(
      subscriptions: stats,
      playlists: stats,
      playlistItems: stats,
      favorites: stats,
      watchLater: stats,
      history: stats,
      warnings: [],
      errors: [],
      finishedAt: 1
    )
  }

  private var counts: LiveYouTubeImportCounts {
    LiveYouTubeImportCounts(
      subscriptions: 1,
      playlists: 1,
      playlistItems: 1,
      favorites: 1,
      watchLater: 1,
      history: 1
    )
  }

  private func job(
    id: String,
    status: String,
    phase: String,
    progress: Int
  ) -> LiveYouTubeImportJob {
    LiveYouTubeImportJob(
      jobID: id,
      status: status,
      phase: phase,
      progress: progress,
      createdAt: 1,
      updatedAt: 1,
      expiresAt: 2,
      error: nil
    )
  }
}
