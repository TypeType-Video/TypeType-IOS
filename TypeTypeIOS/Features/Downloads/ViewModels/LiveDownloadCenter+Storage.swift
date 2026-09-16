import Foundation

extension LiveDownloadCenter {
  var storageUsage: Int64 {
    records.reduce(Int64(0)) { total, record in
      guard let fileURL = artifactURL(for: record) else { return total }
      let size = (try? fileManager.attributesOfItem(
        atPath: fileURL.path
      )[.size] as? NSNumber)?.int64Value
      return total + (size ?? 0)
    }
  }

  func cleanOrphanedArtifacts() {
    let referencedNames = Set(records.compactMap(\.localFileName))
    let artifactFiles = (try? fileManager.contentsOfDirectory(
      at: artifactsURL,
      includingPropertiesForKeys: nil
    )) ?? []

    for fileURL in artifactFiles
    where !referencedNames.contains(fileURL.lastPathComponent) {
      try? fileManager.removeItem(at: fileURL)
    }
  }
}
