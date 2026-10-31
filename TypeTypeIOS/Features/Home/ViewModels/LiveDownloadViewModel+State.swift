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

  var progress: Double? {
    guard let value = job?.progressPercent else { return nil }
    return Double(min(max(value, 0), 100)) / 100
  }
}
