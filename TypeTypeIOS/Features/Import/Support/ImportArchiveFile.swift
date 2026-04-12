import Foundation

struct ImportArchiveFile: Identifiable {
  let id: UUID
  let name: String
  let url: URL

  init(name: String, url: URL) {
    self.id = UUID()
    self.name = name
    self.url = url
  }
}

enum ImportArchiveAccess {
  static func prepare(url: URL) throws -> ImportArchiveFile {
    let isScoped = url.startAccessingSecurityScopedResource()
    defer {
      if isScoped {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let safeName = url.lastPathComponent.isEmpty ? "archive.zip" : url.lastPathComponent
    let target = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(UUID().uuidString)-\(safeName)")

    if FileManager.default.fileExists(atPath: target.path) {
      try FileManager.default.removeItem(at: target)
    }
    try FileManager.default.copyItem(at: url, to: target)
    return ImportArchiveFile(name: safeName, url: target)
  }
}
