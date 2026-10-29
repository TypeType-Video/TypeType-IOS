import Foundation

protocol LiveImportServiceProtocol {
  func restorePipePipe(
    data: Data,
    fileName: String,
    timeMode: String
  ) async throws -> LivePipePipeRestoreResult
  func createYouTubeImport(
    fileURL: URL,
    fileName: String
  ) async throws -> LiveYouTubeImportJob
  func youTubeJob(id: String) async throws -> LiveYouTubeImportJob
  func youTubePreview(id: String) async throws -> LiveYouTubeImportPreview
  func commitYouTube(
    id: String,
    options: LiveYouTubeImportCommit
  ) async throws -> LiveYouTubeImportJob
  func youTubeReport(id: String) async throws -> LiveYouTubeImportReport
  func exportTypeTypeBackup(
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> URL
  func restoreTypeTypeBackup(
    data: Data,
    fileName: String,
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> LiveTypeTypeRestoreSummary
  func restoreTypeTypeBackup(
    fileURL: URL,
    originalName: String,
    categories: Set<LiveTypeTypeBackupCategory>,
    progress: @escaping @Sendable (LiveTypeTypeBackupPhase, Double) -> Void
  ) async throws -> LiveTypeTypeRestoreSummary
}
