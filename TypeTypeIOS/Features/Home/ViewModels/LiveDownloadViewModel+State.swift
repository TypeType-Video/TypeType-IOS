import Foundation

@MainActor
extension LiveDownloadViewModel {
  var canStart: Bool {
    state == .idle || isTerminal
  }

  var isWorking: Bool {
    state == .creating || state == .tracking
  }

  var isTerminal: Bool {
    switch state {
    case .done, .failed:
      return true
    default:
      return false
    }
  }

  var savingProgress: Double? {
    recordID.flatMap { center.savingProgress[$0] }
  }

  var waitingMessage: String? {
    guard state == .tracking, let recordID else { return nil }
    return center.record(id: recordID)?.failureMessage
  }

  var artifactURL: URL? {
    guard let recordID, let record = center.record(id: recordID) else {
      return nil
    }
    return center.artifactURL(for: record)
  }

  var progress: Double? {
    guard let value = job?.progressPercent else { return nil }
    return Double(min(max(value, 0), 100)) / 100
  }
}
