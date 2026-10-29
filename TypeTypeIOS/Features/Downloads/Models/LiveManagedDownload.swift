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
  var artifactChecksum: String?
  var failureMessage: String?
  /// Watch-page metadata captured at download time. Optional: records
  /// persisted before this field existed decode as nil.
  var metadata: LiveOfflineVideoMetadata?

  var progress: Double? {
    // The artifact fetch reports no percentage, and a full bar would read as stalled.
    guard state != .saving else { return nil }
    guard let value = job.progressPercent else { return nil }
    return Double(min(max(value, 0), 100)) / 100
  }
}

/// Everything the offline watch page needs beyond title and URL, frozen at
/// download time so the page renders without a server.
struct LiveOfflineVideoMetadata: Codable, Equatable {
  let thumbnailURL: String
  let uploaderName: String
  let uploaderURL: String
  let uploaderAvatarURL: String
  let duration: Int64
  let viewCount: Int64
  let uploadDate: String
  let uploaded: Int64
  let uploaderVerified: Bool
  let shortDescription: String?
  let publishedAt: Int64?
  let streamType: String
  let isShortFormContent: Bool
  let isLive: Bool
  let isPostLive: Bool
  let isLiveContent: Bool
  let requiresMembership: Bool
  /// Engagement at download time (-1 when unknown).
  let likeCount: Int64
  let dislikeCount: Int64
  /// The channel avatar saved next to the artifact (offline rendering).
  let localAvatarFileName: String?

  init(
    video: LiveVideoItem,
    likeCount: Int64 = -1,
    dislikeCount: Int64 = -1,
    localAvatarFileName: String? = nil
  ) {
    thumbnailURL = video.thumbnailURL
    uploaderName = video.uploaderName
    uploaderURL = video.uploaderURL
    uploaderAvatarURL = video.uploaderAvatarURL
    duration = video.duration
    viewCount = video.viewCount
    uploadDate = video.uploadDate
    uploaded = video.uploaded
    uploaderVerified = video.uploaderVerified
    shortDescription = video.shortDescription
    publishedAt = video.publishedAt
    streamType = video.streamType
    isShortFormContent = video.isShortFormContent
    isLive = video.isLive
    isPostLive = video.isPostLive
    self.isLiveContent = video.isLiveContent
    self.requiresMembership = video.requiresMembership
    self.likeCount = likeCount
    self.dislikeCount = dislikeCount
    self.localAvatarFileName = localAvatarFileName
  }
}
