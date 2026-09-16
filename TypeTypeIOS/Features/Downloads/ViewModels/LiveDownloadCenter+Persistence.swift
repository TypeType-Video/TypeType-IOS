import Foundation

extension LiveDownloadCenter {
  func prepareStorage() {
    do {
      try fileManager.createDirectory(
        at: artifactsURL,
        withIntermediateDirectories: true
      )
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      var storedRootURL = rootURL
      try? storedRootURL.setResourceValues(values)
    } catch {
      AppLogger.app.error(
        "Download storage creation failed: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  func load() {
    guard let data = try? Data(contentsOf: indexURL) else { return }
    do {
      records = try JSONDecoder().decode(
        [LiveManagedDownload].self,
        from: data
      )
      var changed = false
      for index in records.indices
      where records[index].state == .ready
        && artifactURL(for: records[index]) == nil {
        records[index].state = .failed
        records[index].failureMessage =
          "The downloaded file is no longer available on this device."
        changed = true
      }

      for index in records.indices where records[index].state == .ready {
        guard let artifactURL = artifactURL(for: records[index]) else {
          continue
        }
        let checksum = try? LiveDownloadChecksum.sha256(
          at: artifactURL,
          fileManager: fileManager
        )
        if let expectedChecksum = records[index].artifactChecksum {
          if checksum != expectedChecksum {
            records[index].state = .failed
            records[index].failureMessage =
              "The downloaded file no longer matches its integrity checksum."
            changed = true
          }
        } else if let checksum {
          records[index].artifactChecksum = checksum
          changed = true
        } else {
          records[index].state = .failed
          records[index].failureMessage =
            "The downloaded file could not be checked for integrity."
          changed = true
        }
      }

      cleanOrphanedArtifacts()
      if changed { persist() }
    } catch {
      AppLogger.app.error(
        "Download index decoding failed: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  func persist() {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys]
      let data = try encoder.encode(records)
      try data.write(to: indexURL, options: .atomic)
    } catch {
      AppLogger.app.error(
        "Download index persistence failed: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  nonisolated static func resetPersistentState(
    fileManager: FileManager = .default
  ) {
    try? fileManager.removeItem(at: defaultRootURL())
  }

  nonisolated static func defaultRootURL() -> URL {
    let base = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first ?? FileManager.default.temporaryDirectory
    return base
      .appendingPathComponent("TypeType", isDirectory: true)
      .appendingPathComponent("Downloads", isDirectory: true)
  }
}
