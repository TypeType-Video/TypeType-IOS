import Foundation

@MainActor
final class LiveDownloadCenter: ObservableObject {
  typealias ScopeProvider = () -> LiveDownloadScope?

  @Published var records: [LiveManagedDownload] = []
  @Published var message: String?
  @Published var storageUsage: Int64 = 0
  // What already reached the device while saving. Not persisted.
  @Published var savingProgress: [String: DownloadProgress] = [:]
  var resumeData: [String: Data] = [:]

  let service: LiveDownloaderServiceProtocol
  let scopeProvider: ScopeProvider
  let fileManager: FileManager
  let mediaValidator: LiveOfflineMediaValidating
  let rootURL: URL
  let indexURL: URL
  let artifactsURL: URL
  let retryPolicy: LiveDownloadRetryPolicy
  var activeScope: LiveDownloadScope?
  var trackingTasks: [String: Task<Void, Never>] = [:]
  var refreshingRecordIDs: Set<String> = []
  private var integrityTask: Task<Void, Never>?

  init(
    service: LiveDownloaderServiceProtocol,
    scopeProvider: @escaping ScopeProvider,
    rootURL: URL = LiveDownloadCenter.defaultRootURL(),
    fileManager: FileManager = .default,
    mediaValidator: LiveOfflineMediaValidating =
      LiveOfflineMediaValidator(),
    retryPolicy: LiveDownloadRetryPolicy = .standard
  ) {
    self.service = service
    self.scopeProvider = scopeProvider
    self.fileManager = fileManager
    self.mediaValidator = mediaValidator
    self.retryPolicy = retryPolicy
    self.rootURL = rootURL
    indexURL = rootURL.appendingPathComponent(
      "downloads.json",
      isDirectory: false
    )
    artifactsURL = rootURL.appendingPathComponent(
      "Artifacts",
      isDirectory: true
    )
    prepareStorage()
    load()
    integrityTask = Task { [weak self] in
      await self?.verifyArtifacts()
    }
  }

  deinit {
    trackingTasks.values.forEach { $0.cancel() }
    integrityTask?.cancel()
  }

  var visibleRecords: [LiveManagedDownload] {
    guard let scope = scopeProvider() else { return [] }
    return records
      .filter { $0.scope == scope }
      .sorted { $0.createdAt > $1.createdAt }
  }

  var activeCount: Int {
    visibleRecords.filter(\.state.isActive).count
  }

  var activeTrackingCount: Int {
    trackingTasks.count
  }

  func cancelTracking() {
    trackingTasks.values.forEach { $0.cancel() }
    trackingTasks.removeAll()
    activeScope = nil
  }

  func activate() async {
    let scope = scopeProvider()
    if activeScope != scope {
      trackingTasks.values.forEach { $0.cancel() }
      trackingTasks.removeAll()
      activeScope = scope
    }
    guard scope != nil else { return }
    await refresh()
    for record in visibleRecords where record.state.isActive {
      track(record.id)
    }
  }

  func artifactURL(for record: LiveManagedDownload) -> URL? {
    guard let fileName = record.localFileName else { return nil }
    let url = artifactsURL.appendingPathComponent(fileName)
    guard fileManager.fileExists(atPath: url.path) else {
      return nil
    }
    return url
  }

  func record(id: String) -> LiveManagedDownload? {
    records.first { $0.id == id }
  }

  func progress(for record: LiveManagedDownload) -> Double? {
    record.state == .saving ? savingProgress[record.id]?.fraction : record.progress
  }
}

enum LiveDownloadCenterError: LocalizedError {
  case missingScope
  case duplicateActiveDownload(mode: String)

  var errorDescription: String? {
    switch self {
    case .missingScope:
      return "Sign in to an instance before starting a download."
    case let .duplicateActiveDownload(mode):
      return "A \(mode) download for this video is already active."
    }
  }
}
