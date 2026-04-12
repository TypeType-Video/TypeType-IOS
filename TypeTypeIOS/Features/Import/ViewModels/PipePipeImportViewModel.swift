import Foundation

@MainActor
final class PipePipeImportViewModel: ObservableObject {
  @Published private(set) var isImporting: Bool = false
  @Published private(set) var summary: PipePipeRestoreSummary?
  @Published var errorMessage: String?

  private let service: PipePipeImportServiceProtocol

  init(service: PipePipeImportServiceProtocol) {
    self.service = service
  }

  func importArchive(fileURL: URL) async {
    guard !isImporting else { return }
    isImporting = true
    summary = nil
    errorMessage = nil
    do {
      summary = try await service.restore(archiveURL: fileURL, timeMode: "normalized")
      isImporting = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "PipePipe import failed."
      isImporting = false
    } catch {
      errorMessage = "PipePipe import failed."
      isImporting = false
    }
  }
}
