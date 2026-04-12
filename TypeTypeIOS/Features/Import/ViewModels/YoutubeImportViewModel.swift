import Foundation

@MainActor
final class YoutubeImportViewModel: ObservableObject {
  @Published private(set) var isBusy: Bool = false
  @Published private(set) var job: YoutubeImportJobStatus?
  @Published private(set) var preview: YoutubeImportPreview?
  @Published private(set) var report: YoutubeImportReport?
  @Published var errorMessage: String?

  private let service: YoutubeImportServiceProtocol

  init(service: YoutubeImportServiceProtocol) {
    self.service = service
  }

  func startImport(archiveURL: URL) async {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    preview = nil
    report = nil
    do {
      let created = try await service.create(archiveURL: archiveURL)
      job = created
      preview = try await service.preview(jobID: created.jobID)
      job = try await service.commit(jobID: created.jobID)
      try await refreshStatusAndReport(jobID: created.jobID)
      isBusy = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "YouTube import failed."
      isBusy = false
    } catch {
      errorMessage = "YouTube import failed."
      isBusy = false
    }
  }

  func refreshStatusAndReport(jobID: String) async throws {
    let latestStatus = try await service.status(jobID: jobID)
    job = latestStatus
    if latestStatus.status == "completed" {
      report = try await service.report(jobID: jobID)
    }
  }
}
