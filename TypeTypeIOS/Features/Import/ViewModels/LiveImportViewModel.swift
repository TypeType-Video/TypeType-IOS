import Foundation

@MainActor
final class LiveImportViewModel: ObservableObject {
  @Published var isRunning = false
  @Published var pipePipeResult: LivePipePipeRestoreResult?
  @Published var youTubeArchives: [LiveYouTubeImportArchive] = []
  @Published var activeYouTubeArchiveID: UUID?
  @Published var errorMessage: String?
  @Published var selectedBackupCategories: Set<LiveTypeTypeBackupCategory> = Set(
    LiveTypeTypeBackupCategory.allCases
  )
  @Published var exportedBackupURL: URL?
  @Published var typeTypeRestoreSummary: LiveTypeTypeRestoreSummary?
  @Published var isExportingBackup = false
  @Published var isRestoringBackup = false
  @Published private(set) var backupPhase = LiveTypeTypeBackupPhase.preparing
  @Published private(set) var backupProgress = 0.0
  @Published private(set) var hasResumableRestore = false

  let service: LiveImportServiceProtocol
  private let operationStore: LiveTypeTypeRestoreOperationStore
  private var restoreTask: Task<Void, Never>?

  init(
    service: LiveImportServiceProtocol,
    operationStore: LiveTypeTypeRestoreOperationStore = LiveTypeTypeRestoreOperationStore()
  ) {
    self.service = service
    self.operationStore = operationStore
    hasResumableRestore = operationStore.load() != nil
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

  var canStartYouTubeQueue: Bool {
    !isRunning && youTubeArchives.contains { archive in
      switch archive.state {
      case .queued, .failed:
        return true
      default:
        return false
      }
    }
  }

  var canExportTypeTypeBackup: Bool {
    !isRunning && !selectedBackupCategories.isEmpty
  }

  func toggleBackupCategory(_ category: LiveTypeTypeBackupCategory) {
    guard !isRunning else { return }
    if selectedBackupCategories.contains(category) {
      selectedBackupCategories.remove(category)
    } else {
      selectedBackupCategories.insert(category)
    }
  }

  func exportTypeTypeBackup() async {
    guard canExportTypeTypeBackup else { return }
    isRunning = true
    isExportingBackup = true
    errorMessage = nil
    exportedBackupURL = nil
    defer {
      isRunning = false
      isExportingBackup = false
    }
    do {
      exportedBackupURL = try await service.exportTypeTypeBackup(
        categories: selectedBackupCategories
      )
    } catch {
      errorMessage = Self.message(for: error)
    }
  }

  func restoreTypeTypeBackup(url: URL) async {
    guard !isRunning else { return }
    errorMessage = nil
    typeTypeRestoreSummary = nil
    restoreTask = Task {
      await runTypeTypeRestore(sourceURL: url, originalName: url.lastPathComponent)
    }
    await restoreTask?.value
  }

  func loadResumableRestore() {
    hasResumableRestore = operationStore.load() != nil
  }

  func resumeTypeTypeRestore() {
    guard !isRunning, let operation = operationStore.load() else { return }
    selectedBackupCategories = Set(
      operation.categories.compactMap(LiveTypeTypeBackupCategory.init)
    )
    errorMessage = nil
    typeTypeRestoreSummary = nil
    restoreTask = Task {
      await runTypeTypeRestore(
        sourceURL: operation.sourceURL,
        originalName: operation.originalName,
        skipPreparation: operation.phase != .preparing
      )
    }
  }

  func cancelTypeTypeRestore() {
    guard isRestoringBackup else { return }
    restoreTask?.cancel()
    isRunning = false
    isRestoringBackup = false
    hasResumableRestore = operationStore.load() != nil
  }

  private func runTypeTypeRestore(
    sourceURL: URL,
    originalName: String,
    skipPreparation: Bool = false
  ) async {
    isRunning = true
    isRestoringBackup = true
    defer {
      isRunning = false
      isRestoringBackup = false
    }
    do {
      var stagedURL = sourceURL
      if !skipPreparation {
        stagedURL = try await stageSource(
          sourceURL,
          originalName: originalName
        )
        let operation = LiveTypeTypeRestoreOperation(
          sourceURL: stagedURL,
          originalName: originalName,
          categories: selectedBackupCategories.map(\.rawValue).sorted(),
          phase: .filtering
        )
        try operationStore.save(operation)
        hasResumableRestore = true
      }

      let summary = try await service.restoreTypeTypeBackup(
        fileURL: stagedURL,
        originalName: originalName,
        categories: selectedBackupCategories,
        progress: { [weak self] phase, fraction in
          Task { @MainActor [weak self] in
            self?.setBackupProgress(phase: phase, fraction: fraction)
          }
        }
      )
      typeTypeRestoreSummary = summary
      backupPhase = .completed
      backupProgress = 1
      if let operation = operationStore.load() {
        operationStore.clear(operation)
      }
      hasResumableRestore = false
    } catch is CancellationError {
      backupPhase = .preparing
    } catch {
      errorMessage = Self.message(for: error)
    }
  }

  private func stageSource(
    _ sourceURL: URL,
    originalName: String
  ) async throws -> URL {
    setBackupProgress(phase: .preparing, fraction: 0.02)
    return try await Task.detached(priority: .userInitiated) {
      let granted = sourceURL.startAccessingSecurityScopedResource()
      defer {
        if granted {
          sourceURL.stopAccessingSecurityScopedResource()
        }
      }

      let source = try FileHandle(forReadingFrom: sourceURL)
      defer { try? source.close() }
      let destinationURL = try LiveTypeTypeRestoreOperationStore.standard
        .makeStagedSourceURL(originalName: originalName)
      try LiveTypeTypeRestoreOperationStore.standard.ensureDirectory()
      guard FileManager.default.createFile(
        atPath: destinationURL.path,
        contents: nil
      ) else {
        throw LiveTypeTypeBackupOperationError.cannotCreateStagedFile
      }
      let destination = try FileHandle(forWritingTo: destinationURL)
      defer { try? destination.close() }

      let sourceSize = (try sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
      var copied = 0
      while let chunk = try source.read(upToCount: 1_048_576), !chunk.isEmpty {
        try destination.write(contentsOf: chunk)
        copied += chunk.count
        let fraction = sourceSize > 0 ? Double(copied) / Double(sourceSize) : 1
        Task { @MainActor in
          self.setBackupProgress(phase: .preparing, fraction: fraction * 0.25)
        }
      }
      return destinationURL
    }.value
  }

  private func setBackupProgress(
    phase: LiveTypeTypeBackupPhase,
    fraction: Double
  ) {
    backupPhase = phase
    backupProgress = min(max(fraction, 0), 1)
  }

  var youTubeOverallProgress: Double {
    guard !youTubeArchives.isEmpty else { return 0 }
    let total = youTubeArchives.reduce(0) { $0 + $1.progress }
    return Double(total) / Double(youTubeArchives.count * 100)
  }

  var completedYouTubeArchiveCount: Int {
    youTubeArchives.filter {
      if case .completed = $0.state { return true }
      return false
    }.count
  }

  func queueYouTube(urls: [URL]) {
    guard !isRunning else { return }
    var knownURLs = Set(
      youTubeArchives.map { $0.url.standardizedFileURL }
    )
    let additions = urls
      .filter { $0.pathExtension.lowercased() == "zip" }
      .filter { knownURLs.insert($0.standardizedFileURL).inserted }
      .map(LiveYouTubeImportArchive.init(url:))
    youTubeArchives.append(contentsOf: additions)
  }

  func removeYouTubeArchive(id: UUID) {
    guard !isRunning else { return }
    youTubeArchives.removeAll { $0.id == id }
  }

  func clearYouTubeQueue() {
    guard !isRunning else { return }
    youTubeArchives.removeAll()
    activeYouTubeArchiveID = nil
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
      errorMessage = Self.message(for: error)
    }
  }

  static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The import could not be completed."
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
