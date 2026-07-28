import Foundation

struct LiveDownloadScope: Codable, Equatable, Hashable {
  let serverID: String
  let accountID: String
}

enum LiveManagedDownloadState: String, Codable {
  case queued
  case preparing
  case downloading
  case finalizing
  case saving
  case ready
  case failed
  case cancelled

  var title: String {
    switch self {
    case .queued: return "Waiting in queue"
    case .preparing: return "Preparing media"
    case .downloading: return "Downloading"
    case .finalizing: return "Finalizing"
    case .saving: return "Saving on this device"
    case .ready: return "Ready offline"
    case .failed: return "Download failed"
    case .cancelled: return "Cancelled"
    }
  }

  var systemImage: String {
    switch self {
    case .queued: return "clock"
    case .preparing: return "wand.and.stars"
    case .downloading: return "arrow.down.circle"
    case .finalizing: return "arrow.triangle.2.circlepath"
    case .saving: return "externaldrive.badge.plus"
    case .ready: return "checkmark.circle.fill"
    case .failed: return "exclamationmark.triangle.fill"
    case .cancelled: return "xmark.circle"
    }
  }

  var isActive: Bool {
    switch self {
    case .queued, .preparing, .downloading, .finalizing, .saving:
      return true
    case .ready, .failed, .cancelled:
      return false
    }
  }

  var canRetry: Bool {
    self == .failed || self == .cancelled
  }

  var canCancel: Bool {
    switch self {
    case .queued, .preparing, .downloading, .finalizing:
      return true
    case .saving, .ready, .failed, .cancelled:
      return false
    }
  }
}

struct LiveManagedDownload: Codable, Equatable, Identifiable {
  let id: String
  let scope: LiveDownloadScope
  let videoURL: String
  let title: String
  var options: LiveDownloadOptions
  let createdAt: Date
  var updatedAt: Date
  var job: LiveDownloadJob
  var state: LiveManagedDownloadState
  var localFileName: String?
  var failureMessage: String?

  var progress: Double? {
    guard let value = job.progressPercent else { return nil }
    return Double(min(max(value, 0), 100)) / 100
  }
}
