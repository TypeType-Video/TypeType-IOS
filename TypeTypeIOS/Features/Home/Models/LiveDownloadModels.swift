import Foundation

enum LiveDownloadMode: String, CaseIterable, Identifiable {
  case video
  case audio
  case thumbnail

  var id: String { rawValue }

  var title: String {
    rawValue.capitalized
  }
}

struct LiveDownloadJob: Codable, Equatable, Identifiable {
  let id: String
  let url: String
  let status: String
  let title: String?
  let resolved: LiveResolvedDownload?
  let progressPercent: Int?
  let downloadedBytes: Int64?
  let totalBytes: Int64?
  let speedBytesPerSecond: Int64?
  let etaSeconds: Int?
  let stage: String?
  let queuedAt: String?
  let startedAt: String?
  let finishedAt: String?
  let queueWaitMilliseconds: Int64?
  let runTimeMilliseconds: Int64?
  let errorCode: String?
  let error: String?

  private enum CodingKeys: String, CodingKey {
    case id, url, status, title, resolved, progressPercent
    case downloadedBytes, totalBytes, speedBytesPerSecond, etaSeconds
    case stage, queuedAt, startedAt, finishedAt, errorCode, error
    case queueWaitMilliseconds = "queueWaitMs"
    case runTimeMilliseconds = "runTimeMs"
  }
}

struct LiveResolvedDownload: Codable, Equatable {
  let videoItag: String?
  let audioItag: String?
  let height: Int?
  let fps: Int?
  let videoCodec: String?
  let audioCodec: String?
  let container: String?
  let bitrate: Int?
  let fileName: String?
}

struct LiveDownloadOptions: Codable, Equatable {
  let mode: String
  let quality: String
  let format: String
  let height: Int?
  let videoCodec: String?
  let audioCodec: String?
  let allowQualityFallback: Bool
  let sponsorBlock: Bool
  let sponsorBlockCategories: [String]
  let thumbnailOnly: Bool
  let subtitles: LiveDownloadSubtitleOptions

  init(
    mode: String,
    quality: String,
    format: String,
    height: Int? = nil,
    videoCodec: String? = nil,
    audioCodec: String? = nil,
    allowQualityFallback: Bool,
    sponsorBlock: Bool,
    sponsorBlockCategories: [String],
    thumbnailOnly: Bool,
    subtitles: LiveDownloadSubtitleOptions
  ) {
    self.mode = mode
    self.quality = quality
    self.format = format
    self.height = height
    self.videoCodec = videoCodec
    self.audioCodec = audioCodec
    self.allowQualityFallback = allowQualityFallback
    self.sponsorBlock = sponsorBlock
    self.sponsorBlockCategories = sponsorBlockCategories
    self.thumbnailOnly = thumbnailOnly
    self.subtitles = subtitles
  }
}

struct LiveDownloadSubtitleOptions: Codable, Equatable {
  let enabled: Bool
  let auto: Bool
  let embed: Bool
  let languages: [String]
  let format: String
}

struct LiveDownloadRequest: Encodable {
  let url: String
  let options: LiveDownloadOptions
}
