import Foundation

extension LiveDownloadCenter {
  /// Hashing a video takes seconds per gigabyte, so it runs off the main thread and the results
  /// land afterwards.
  func verifyArtifacts() async {
    let candidates = records.compactMap { record -> (id: String, url: URL, expected: String?)? in
      guard record.state == .ready, let url = artifactURL(for: record) else { return nil }
      return (record.id, url, record.artifactChecksum)
    }
    var changed = false
    for candidate in candidates {
      let checksum = try? await Self.checksum(of: candidate.url)
      guard !Task.isCancelled else { return }
      guard let index = records.firstIndex(where: { $0.id == candidate.id }),
        records[index].state == .ready
      else { continue }
      if let expected = candidate.expected {
        guard checksum != expected else { continue }
        records[index].state = .failed
        records[index].failureMessage = "The downloaded file no longer matches its integrity checksum."
      } else if let checksum {
        records[index].artifactChecksum = checksum
      } else {
        records[index].state = .failed
        records[index].failureMessage = "The downloaded file could not be checked for integrity."
      }
      changed = true
    }
    if changed { persist() }
    await refreshStorageUsage()
  }

  func refreshStorageUsage() async {
    let urls = records.compactMap(artifactURL(for:))
    storageUsage = await Task.detached(priority: .utility) {
      urls.reduce(Int64(0)) { total, url in
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value
        return total + (size ?? 0)
      }
    }.value
  }

  static func checksum(of url: URL) async throws -> String {
    try await Task.detached(priority: .utility) {
      try LiveDownloadChecksum.sha256(at: url)
    }.value
  }
}
