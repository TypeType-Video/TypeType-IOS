import Foundation

@MainActor
final class LiveImportViewModel: ObservableObject {
  @Published var isRunning = false
  @Published var pipePipeResult: LivePipePipeRestoreResult?
  @Published var youTubeArchives: [LiveYouTubeImportArchive] = []
  @Published var activeYouTubeArchiveID: UUID?
  @Published var errorMessage: String?

  let service: LiveImportServiceProtocol

  init(service: LiveImportServiceProtocol) {
    self.service = service
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
