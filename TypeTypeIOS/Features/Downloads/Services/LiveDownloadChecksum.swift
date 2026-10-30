import CryptoKit
import Foundation

enum LiveDownloadChecksum {
  static func sha256(
    at fileURL: URL,
    fileManager: FileManager = .default
  ) throws -> String {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      throw LiveDownloadChecksumError.missingFile
    }

    let handle = try FileHandle(forReadingFrom: fileURL)
    defer { try? handle.close() }

    var hasher = SHA256()
    while let data = try handle.read(upToCount: 1 << 20) {
      hasher.update(data: data)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }
}

enum LiveDownloadChecksumError: LocalizedError {
  case missingFile

  var errorDescription: String? {
    "The downloaded file is no longer available."
  }
}
