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

struct LiveDownloadJob: Decodable, Equatable, Identifiable {
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

struct LiveResolvedDownload: Decodable, Equatable {
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

struct LiveDownloadOptions: Encodable {
  let mode: String
  let quality: String
  let format: String
  let allowQualityFallback: Bool
  let sponsorBlock: Bool
  let sponsorBlockCategories: [String]
  let thumbnailOnly: Bool
  let subtitles: LiveDownloadSubtitleOptions
}

struct LiveDownloadSubtitleOptions: Encodable {
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
