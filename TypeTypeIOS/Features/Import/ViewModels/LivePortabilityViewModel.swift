import SwiftUI

@MainActor
final class LivePortabilityViewModel: ObservableObject {
  enum Mode: String, CaseIterable, Identifiable {
    case export
    case `import`

    var id: String { rawValue }
    var title: String { self == .export ? "Export" : "Import" }
    var direction: LivePortabilityDirection {
      self == .export ? .export : .import
    }
  }

  enum State: Equatable {
    case idle
    case loadingFormats
    case loaded
    case failed(String)
  }

  @Published var mode = Mode.import
  @Published private(set) var formats: [LivePortabilityFormat] = []
  @Published private(set) var state = State.idle
  @Published var selectedFormat: LivePortabilityFormat?
  @Published var selectedCategories: Set<String> = []
  @Published var duplicatePolicy = LivePortabilityDuplicatePolicy.skip
  @Published private(set) var job: LivePortabilityJob?
  @Published private(set) var isStartingJob = false
  @Published private(set) var isApplying = false
  @Published private(set) var isCancelling = false
  @Published var selectedFileName: String?
  @Published var selectedFileURL: URL?
  @Published var shareURL: URL?
  @Published var errorMessage: String?

  private let service: LivePortabilityServiceProtocol
  private var watchTask: Task<Void, Never>?

  init(service: LivePortabilityServiceProtocol) {
    self.service = service
  }

  deinit {
    watchTask?.cancel()
  }

  var availableCategories: [LiveTypeTypeBackupCategory] {
    guard let format = selectedFormat else { return [] }
    return LiveTypeTypeBackupCategory.allCases.filter {
      format.supports(direction: mode.direction, category: $0)
    }
  }

  var activeCategories: [LiveTypeTypeBackupCategory] {
    guard job?.state == .ready else { return availableCategories }
    return previewCategories
  }

  var previewCategories: [LiveTypeTypeBackupCategory] {
    job?.preview?.counts.keys.compactMap(LiveTypeTypeBackupCategory.init(rawValue:)) ?? []
  }

  var canStart: Bool {
    selectedFormat != nil
      && !selectedCategories.isEmpty
      && !isStartingJob
      && job == nil
      && (mode != .import || selectedFileURL != nil)
  }

  func prepare() async {
    guard state == .idle else { return }
    await loadFormats()
  }

  func loadFormats() async {
    state = .loadingFormats
    do {
      formats = try await service.formats().filter { format in
        format.capabilities.contains { $0.directions.contains(mode.rawValue) }
      }
      selectedFormat = formats.first
      selectedCategories = []
      state = .loaded
    } catch {
      state = .failed(message(for: error))
    }
  }

  func selectMode(_ mode: Mode) async {
    guard mode != self.mode else { return }
    self.mode = mode
    job = nil
    selectedCategories = []
    selectedFileURL = nil
    selectedFileName = nil
    await loadFormats()
  }

  func selectFormat(_ format: LivePortabilityFormat) {
    selectedFormat = format
    selectedCategories = []
    job = nil
  }

  func toggle(_ category: LiveTypeTypeBackupCategory) {
    if selectedCategories.contains(category.rawValue) {
      selectedCategories.remove(category.rawValue)
    } else {
      selectedCategories.insert(category.rawValue)
    }
  }

  func selectFile(_ url: URL) {
    selectedFileURL = url
    selectedFileName = url.lastPathComponent
  }

  func start() async {
    guard let format = selectedFormat, !selectedCategories.isEmpty else { return }
    isStartingJob = true
    errorMessage = nil
    defer { isStartingJob = false }
    do {
      let job = mode == .export
        ? try await service.startExport(
          format: format.format,
          categories: selectedCategories.reduce(into: []) {
            $0.insert(LiveTypeTypeBackupCategory(rawValue: $1)!)
          }
        )
        : try await startImport(format: format)
      self.job = job
      watch(job.id)
    } catch {
      errorMessage = message(for: error)
    }
  }

  func apply() async {
    guard let job, job.state == .ready, !isApplying else { return }
    let categories = previewCategories
    guard !categories.isEmpty else { return }
    isApplying = true
    errorMessage = nil
    defer { isApplying = false }
    do {
      self.job = try await service.apply(
        id: job.id,
        categories: Set(categories),
        duplicatePolicy: duplicatePolicy
      )
      watch(job.id)
    } catch {
      errorMessage = message(for: error)
    }
  }

  func cancel() async {
    guard let job, !job.isTerminal, !isCancelling else { return }
    isCancelling = true
    defer { isCancelling = false }
    do {
      self.job = try await service.cancel(id: job.id)
    } catch {
      errorMessage = message(for: error)
    }
  }

  func reset() async {
    let oldJob = job
    job = nil
    selectedCategories = []
    selectedFileURL = nil
    selectedFileName = nil
    watchTask?.cancel()
    if let oldJob {
      do {
        try await service.delete(id: oldJob.id)
      } catch {
        AppLogger.network.failure("Deleting a finished portability job", error)
      }
    }
  }

  func prepareDownload(kind: LivePortabilityDownloadKind) async {
    guard let job else { return }
    do {
      shareURL = kind == .artifact
        ? try await service.artifact(id: job.id)
        : try await service.report(id: job.id)
    } catch {
      errorMessage = message(for: error)
    }
  }

  private func startImport(format: LivePortabilityFormat) async throws -> LivePortabilityJob {
    guard let fileURL = selectedFileURL else {
      throw LivePortabilityFailure.fileMissing
    }
    return try await service.startImport(
      fileURL: fileURL,
      fileName: selectedFileName ?? fileURL.lastPathComponent,
      format: format.format
    )
  }

  private func watch(_ jobID: String) {
    watchTask?.cancel()
    watchTask = Task { await pollJob(jobID) }
  }

  private func pollJob(_ jobID: String) async {
    while !Task.isCancelled {
      do {
        let updated = try await service.job(id: jobID)
        job = updated

        if updated.state == .ready {
          let categoryNames = Array((updated.preview?.counts ?? [:]).keys)
          selectedCategories = Set(categoryNames)
          return
        }
        if updated.isTerminal { return }
      } catch {
        if job?.state != .ready, job?.isTerminal != true {
          errorMessage = message(for: error)
        }
      }

      try? await Task.sleep(for: .seconds(1))
    }
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? error.localizedDescription
  }
}

enum LivePortabilityDownloadKind {
  case artifact
  case report
}

enum LivePortabilityFailure: LocalizedError {
  case fileMissing

  var errorDescription: String? {
    switch self {
    case .fileMissing: return "Choose a backup file first."
    }
  }
}
