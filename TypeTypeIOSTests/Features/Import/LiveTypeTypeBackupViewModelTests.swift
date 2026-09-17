import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveTypeTypeBackupViewModelTests: XCTestCase {
  func testToggleCategoryControlsExportSelection() {
    let viewModel = LiveImportViewModel(
      service: NotificationBackupImportServiceStub()
    )

    viewModel.toggleBackupCategory(.settings)
    XCTAssertFalse(viewModel.selectedBackupCategories.contains(.settings))

    viewModel.toggleBackupCategory(.settings)
    XCTAssertTrue(viewModel.selectedBackupCategories.contains(.settings))
  }

  func testExportStoresDownloadedBackupURL() async throws {
    let service = NotificationBackupImportServiceStub()
    let viewModel = LiveImportViewModel(service: service)

    await viewModel.exportTypeTypeBackup()

    XCTAssertTrue(viewModel.isExportingBackup == false)
    XCTAssertEqual(viewModel.exportedBackupURL, service.exportURL)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testRestoreStoresSummary() async throws {
    let service = NotificationBackupImportServiceStub()
    let source = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    try Data("{}".utf8).write(to: source)
    defer { try? FileManager.default.removeItem(at: source) }
    let viewModel = LiveImportViewModel(service: service)

    await viewModel.restoreTypeTypeBackup(url: source)

    XCTAssertEqual(
      viewModel.typeTypeRestoreSummary,
      service.restoreSummary
    )
    XCTAssertNil(viewModel.errorMessage)
  }
}

private final class NotificationBackupImportServiceStub: LiveImportServiceProtocol {
  let exportURL = URL(fileURLWithPath: "/tmp/typetype-backup.json")
  let restoreSummary = LiveTypeTypeRestoreSummary(
    restored: ["subscriptions": 3, "history": 4]
  )

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
    throw NetworkError.invalidResponse
  }

  func youTubeJob(id: String) async throws -> LiveYouTubeImportJob {
    throw NetworkError.invalidResponse
  }

  func youTubePreview(id: String) async throws -> LiveYouTubeImportPreview {
    throw NetworkError.invalidResponse
  }

  func commitYouTube(
    id: String,
    options: LiveYouTubeImportCommit
  ) async throws -> LiveYouTubeImportJob {
    throw NetworkError.invalidResponse
  }

  func youTubeReport(id: String) async throws -> LiveYouTubeImportReport {
    throw NetworkError.invalidResponse
  }

  func exportTypeTypeBackup(
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> URL {
    exportURL
  }

  func restoreTypeTypeBackup(
    data: Data,
    fileName: String,
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> LiveTypeTypeRestoreSummary {
    restoreSummary
  }
}
