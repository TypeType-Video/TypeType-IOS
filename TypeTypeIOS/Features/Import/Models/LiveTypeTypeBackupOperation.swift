import Foundation

enum LiveTypeTypeBackupPhase: String, Codable {
  case preparing
  case filtering
  case uploading
  case finalizing
  case completed
}

struct LiveTypeTypeRestoreOperation: Codable, Equatable {
  var sourceURL: URL
  var originalName: String
  var categories: [String]
  var phase: LiveTypeTypeBackupPhase
}

struct LiveTypeTypeRestoreOperationStore {
  let directory: URL
  let operationURL: URL

  static let standard = LiveTypeTypeRestoreOperationStore()

  init(directory: URL? = nil) {
    let base = directory ?? FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first ?? FileManager.default.temporaryDirectory
    self.directory = base
      .appendingPathComponent("TypeType", isDirectory: true)
      .appendingPathComponent("Imports", isDirectory: true)
    operationURL = self.directory
      .appendingPathComponent("typetype-restore-operation.json")
  }

  func load() -> LiveTypeTypeRestoreOperation? {
    guard let data = try? Data(contentsOf: operationURL) else { return nil }
    return try? JSONDecoder().decode(
      LiveTypeTypeRestoreOperation.self,
      from: data
    )
  }

  func save(_ operation: LiveTypeTypeRestoreOperation) throws {
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(operation)
    try data.write(to: operationURL, options: .atomic)
  }

  func clear() {
    try? FileManager.default.removeItem(at: operationURL)
  }

  func clear(_ operation: LiveTypeTypeRestoreOperation) {
    clear()
    try? FileManager.default.removeItem(at: operation.sourceURL)
  }

  func makeStagedSourceURL(originalName: String) -> URL {
    let safeName = originalName
      .components(separatedBy: CharacterSet(charactersIn: "/:\\?%*|\"<>"))
      .filter { !$0.isEmpty }
      .joined(separator: "-")
    return directory.appendingPathComponent(
      "restore-source-\(UUID().uuidString)-\(safeName)"
    )
  }

  func ensureDirectory() throws {
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
  }
}

enum LiveTypeTypeBackupOperationError: LocalizedError {
  case cannotCreateStagedFile

  var errorDescription: String? {
    "The backup could not be prepared for restore."
  }
}
