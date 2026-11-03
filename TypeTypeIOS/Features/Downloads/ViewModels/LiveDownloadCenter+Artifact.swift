import Foundation

extension LiveDownloadCenter {
  // Throws only a transient failure, so the tracking loop counts it against its retry budget.
  func saveArtifact(for id: String) async throws {
    guard let saving = record(id: id), saving.scope == scopeProvider() else {
      return
    }
    let resume = resumeData.removeValue(forKey: id)
    if resume == nil { savingProgress[id] = nil }
    let startedAt = DispatchTime.now().uptimeNanoseconds
    // Leaving the app suspends the transfer: the extra time lets a short one finish.
    let background = LiveBackgroundActivity(name: "Saving a download")
    defer { background.end() }
    let temporaryURL: URL
    do {
      temporaryURL = try await service.artifact(id: saving.job.id, resumeData: resume) { [weak self] fraction in
        Task { @MainActor in self?.reportSaving(id: id, fraction: fraction) }
      }
    } catch {
      if let interruption = error as? DownloadInterruption {
        resumeData[id] = interruption.resumeData
      } else {
        savingProgress[id] = nil
      }
      if error is CancellationError { throw error }
      AppLogger.network.error(
        "download artifact failed after \(Self.elapsedMs(since: startedAt), privacy: .public)ms resumed=\(resume != nil, privacy: .public): \(Self.message(for: error), privacy: .public)"
      )
      guard var record = record(id: id), record.state == .saving else { return }
      // A refused resume (an expired link, a changed file) is retried from the start, not reported as fatal.
      let transient = Self.isTransientNetworkFailure(error) || resume != nil
      record.state = transient ? .saving : .failed
      record.failureMessage = transient
        ? String(localized: "Waiting for the network to finish saving this download.")
        : String(localized: "The media is ready on the server, but could not be saved on this device.")
          + " " + Self.message(for: error)
      record.updatedAt = Date()
      replace(record)
      if transient { throw error }
      return
    }
    savingProgress[id] = nil
    // A cancel or a delete that lands while the file is on its way wins: the transfer is dropped.
    guard !Task.isCancelled, let record = record(id: id), record.state == .saving else {
      try? fileManager.removeItem(at: temporaryURL)
      return
    }
    AppLogger.network.info(
      "download artifact fetched in \(Self.elapsedMs(since: startedAt), privacy: .public)ms"
    )
    await store(temporaryURL, for: record)
  }

  // Never backwards: a resumed transfer may count only the bytes it adds.
  func reportSaving(id: String, fraction: Double) {
    guard record(id: id)?.state == .saving else { return }
    savingProgress[id] = max(fraction, savingProgress[id] ?? 0)
  }

  private func store(_ temporaryURL: URL, for saving: LiveManagedDownload) async {
    var record = saving
    let fileName = localFileName(for: record)
    let destination = artifactsURL.appendingPathComponent(fileName)
    do {
      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }
      try fileManager.moveItem(at: temporaryURL, to: destination)
      try? fileManager.setAttributes(
        [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
        ofItemAtPath: destination.path
      )
    } catch {
      try? fileManager.removeItem(at: temporaryURL)
      record.state = .failed
      record.failureMessage =
        String(localized: "The media is ready on the server, but could not be saved on this device.")
        + " " + Self.message(for: error)
      record.updatedAt = Date()
      replace(record)
      return
    }
    // Ready as soon as the file is in place; validation and checksum finish later and demote the record only if
    // they fail.
    record.localFileName = fileName
    record.state = .ready
    record.failureMessage = nil
    record.updatedAt = Date()
    replace(record)
    do {
      try await mediaValidator.validate(fileURL: destination, mode: record.options.mode)
      record.artifactChecksum = try await Self.checksum(of: destination)
      record.updatedAt = Date()
      replace(record)
      await refreshStorageUsage()
    } catch {
      try? fileManager.removeItem(at: destination)
      record.state = .failed
      record.failureMessage =
        String(localized: "The download did not pass validation.") + " " + Self.message(for: error)
      record.updatedAt = Date()
      replace(record)
    }
  }

  private static func elapsedMs(since start: UInt64) -> Int {
    Int(Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6)
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
