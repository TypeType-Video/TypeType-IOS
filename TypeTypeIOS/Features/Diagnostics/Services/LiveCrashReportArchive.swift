import Foundation

actor LiveCrashReportArchive {
  private let fileURL: URL
  private let limit = 10

  init(fileURL: URL? = nil) {
    self.fileURL = fileURL ?? URL.applicationSupportDirectory
      .appending(path: "crash-reports.json")
  }

  func reports() -> [LiveCrashReport] {
    guard let data = try? Data(contentsOf: fileURL) else { return [] }
    do {
      return try JSONDecoder().decode([LiveCrashReport].self, from: data)
    } catch {
      AppLogger.app.failure("Reading the crash reports", error)
      return []
    }
  }

  func append(_ newReports: [LiveCrashReport]) {
    guard !newReports.isEmpty else { return }
    let merged = (newReports + reports()).sorted { $0.date > $1.date }
    write(Array(merged.prefix(limit)))
  }

  func clear() {
    write([])
  }

  private func write(_ reports: [LiveCrashReport]) {
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try JSONEncoder().encode(reports).write(to: fileURL, options: [.atomic, .completeFileProtection])
    } catch {
      AppLogger.app.failure("Saving the crash reports", error)
    }
  }
}
