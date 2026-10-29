import Foundation

extension LiveDownloadCenter {
  func saveArtifact(for id: String) async {
    guard var record = record(id: id),
      record.scope == scopeProvider()
    else {
      return
    }
    var savedURL: URL?
    let startedAt = DispatchTime.now().uptimeNanoseconds
    do {
      let temporaryURL = try await service.artifact(id: record.job.id)
      let fetchedMs = Int(
        Double(DispatchTime.now().uptimeNanoseconds - startedAt) / 1e6
      )
      AppLogger.network.info(
        "download artifact fetched in \(fetchedMs, privacy: .public)ms"
      )
      let fileName = localFileName(for: record)
      let destination = artifactsURL.appendingPathComponent(fileName)
      savedURL = destination
      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }
      try fileManager.moveItem(
        at: temporaryURL,
        to: destination
      )
      try? fileManager.setAttributes(
        [
          .protectionKey:
            FileProtectionType.completeUntilFirstUserAuthentication,
        ],
        ofItemAtPath: destination.path
      )
      // Ready the moment the file is in place: the media validation and the
      // full-file checksum take ages on large files and used to hold the
      // "Saving on this device" state hostage. They finish afterwards and
      // demote the record only if they actually fail.
      record.localFileName = fileName
      record.state = .ready
      record.failureMessage = nil
      record.updatedAt = Date()
      replace(record)
      do {
        try await mediaValidator.validate(
          fileURL: destination,
          mode: record.options.mode
        )
        record.artifactChecksum = try LiveDownloadChecksum.sha256(
          at: destination,
          fileManager: fileManager
        )
        record.updatedAt = Date()
        replace(record)
      } catch {
        try? fileManager.removeItem(at: savedURL ?? destination)
        record.state = .failed
        record.failureMessage =
          "The download did not pass validation. " + Self.message(for: error)
        record.updatedAt = Date()
        replace(record)
      }
    } catch {
      let failedMs = Int(
        Double(DispatchTime.now().uptimeNanoseconds - startedAt) / 1e6
      )
      AppLogger.network.error(
        "download artifact failed after \(failedMs, privacy: .public)ms: \(Self.message(for: error), privacy: .public)"
      )
      if Self.isTransientNetworkFailure(error) {
        record.state = .saving
        record.failureMessage =
          "Waiting for the network to finish saving this download."
      } else {
        if let savedURL {
          try? fileManager.removeItem(at: savedURL)
        }
        record.state = .failed
        record.failureMessage =
          "The media is ready on the server, but could not be saved on this device. "
          + Self.message(for: error)
      }
      record.updatedAt = Date()
      replace(record)
    }
  }

  func state(
    for job: LiveDownloadJob
  ) -> LiveManagedDownloadState {
    switch job.status.lowercased() {
    case "done", "completed":
      return .saving
    case "failed":
      return .failed
    case "cancelled", "canceled":
      return .cancelled
    case "queued":
      return .queued
    default:
      switch job.stage?.lowercased() {
      case "download", "downloading": return .downloading
      case "mux", "finalizing": return .finalizing
      default: return .preparing
      }
    }
  }

  func replace(_ record: LiveManagedDownload) {
    guard let index = records.firstIndex(where: { $0.id == record.id })
    else {
      records.append(record)
      persist()
      return
    }
    records[index] = record
    persist()
  }

  private func localFileName(
    for record: LiveManagedDownload
  ) -> String {
    let proposed = record.job.resolved?.fileName?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let fallback = record.title + fallbackExtension(for: record.options)
    let source = proposed.flatMap { $0.isEmpty ? nil : $0 } ?? fallback
    let invalid = CharacterSet(
      charactersIn: "/:\\?%*|\"<>"
    ).union(.newlines)
    let safe = source.components(separatedBy: invalid)
      .filter { !$0.isEmpty }
      .joined(separator: "-")
    return "\(record.id)-\(safe.isEmpty ? "TypeType-media" : safe)"
  }

  private func fallbackExtension(
    for options: LiveDownloadOptions
  ) -> String {
    let format = options.format.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    return format.isEmpty ? "" : ".\(format.lowercased())"
  }
}
