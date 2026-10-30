import Foundation

enum LivePortabilityDownloadKind {
  case artifact
  case report
}

enum LivePortabilityFailure: LocalizedError {
  case fileMissing

  var errorDescription: String? {
    switch self {
    case .fileMissing: return "Choose a backup file first."
    }
  }
}
