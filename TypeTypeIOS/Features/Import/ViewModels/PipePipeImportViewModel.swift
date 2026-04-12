import Foundation

@MainActor
final class PipePipeImportViewModel: ObservableObject {
  @Published private(set) var isImporting: Bool = false
  @Published private(set) var selectedArchiveName: String?
  @Published private(set) var summary: PipePipeRestoreSummary?
  @Published var errorMessage: String?

  private let service: PipePipeImportServiceProtocol
  private var selectedArchiveURL: URL?

  init(service: PipePipeImportServiceProtocol) {
    self.service = service
  }

  func setArchive(_ archive: ImportArchiveFile) {
    selectedArchiveName = archive.name
    selectedArchiveURL = archive.url
    errorMessage = nil
  }

  func clearArchive() {
    selectedArchiveName = nil
    selectedArchiveURL = nil
  }

  func importSelectedArchive() async {
    guard let selectedArchiveURL else {
      errorMessage = "Select a .zip file first."
      return
    }
    guard !isImporting else { return }
    isImporting = true
    summary = nil
    errorMessage = nil
    do {
      summary = try await service.restore(archiveURL: selectedArchiveURL, timeMode: "normalized")
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
