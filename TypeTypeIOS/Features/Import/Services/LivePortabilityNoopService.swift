import Foundation

struct LivePortabilityNoopService: LivePortabilityServiceProtocol {
  struct Unavailable: LocalizedError {
    var errorDescription: String {
      "Portability is unavailable in this context."
    }
  }

  func formats() async throws -> [LivePortabilityFormat] { throw Unavailable() }
  func startExport(
    format: String,
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> LivePortabilityJob { throw Unavailable() }
  func startImport(
    fileURL: URL,
    fileName: String,
    format: String
  ) async throws -> LivePortabilityJob { throw Unavailable() }
  func job(id: String) async throws -> LivePortabilityJob { throw Unavailable() }
  func apply(
    id: String,
    categories: Set<LiveTypeTypeBackupCategory>,
    duplicatePolicy: LivePortabilityDuplicatePolicy
  ) async throws -> LivePortabilityJob { throw Unavailable() }
  func cancel(id: String) async throws -> LivePortabilityJob { throw Unavailable() }
  func delete(id: String) async throws { throw Unavailable() }
  func artifact(id: String) async throws -> URL { throw Unavailable() }
  func report(id: String) async throws -> URL { throw Unavailable() }
}
