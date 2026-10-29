import Foundation

extension LiveDownloadCenter {
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
