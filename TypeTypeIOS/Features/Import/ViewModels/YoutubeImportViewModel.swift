import Foundation

@MainActor
final class YoutubeImportViewModel: ObservableObject {
  @Published private(set) var isBusy: Bool = false
  @Published private(set) var queue: [ImportArchiveFile] = []
  @Published private(set) var currentIndex: Int = 0
  @Published private(set) var job: YoutubeImportJobStatus?
  @Published private(set) var preview: YoutubeImportPreview?
  @Published private(set) var report: YoutubeImportReport?
  @Published var errorMessage: String?

  private let service: YoutubeImportServiceProtocol

  init(service: YoutubeImportServiceProtocol) {
    self.service = service
  }

  var queueCount: Int { queue.count }
  var hasQueue: Bool { !queue.isEmpty }
  var activeFileName: String? {
    guard currentIndex < queue.count else { return nil }
    return queue[currentIndex].name
  }

  func enqueue(_ archives: [ImportArchiveFile]) {
    guard !isBusy else { return }
    queue += archives
    errorMessage = nil
  }

  func clearQueue() {
    guard !isBusy else { return }
    queue = []
    currentIndex = 0
  }

  func removeFromQueue(_ archiveID: UUID) {
    guard !isBusy else { return }
    queue.removeAll(where: { $0.id == archiveID })
    currentIndex = min(currentIndex, max(0, queue.count - 1))
  }

  func startQueuedImport() async {
    guard !isBusy else { return }
    guard !queue.isEmpty else {
      errorMessage = "Add at least one .zip file."
      return
    }
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    preview = nil
    report = nil

    for index in queue.indices {
      currentIndex = index
      let archive = queue[index]
      do {
        let created = try await service.create(archiveURL: archive.url)
        job = created
        preview = try await service.preview(jobID: created.jobID)
        job = try await service.commit(jobID: created.jobID)
        try await refreshStatusAndReport(jobID: created.jobID)
      } catch let error as LocalizedError {
        errorMessage = error.errorDescription ?? "YouTube import failed for \(archive.name)."
        isBusy = false
        return
      } catch {
        errorMessage = "YouTube import failed for \(archive.name)."
        isBusy = false
        return
      }
    }

    isBusy = false
    queue = []
    currentIndex = 0
  }

  func refreshStatusAndReport(jobID: String) async throws {
    let latestStatus = try await service.status(jobID: jobID)
    job = latestStatus
    if latestStatus.status == "completed" {
      report = try await service.report(jobID: jobID)
    }
  }
}
