import AVKit
import Foundation
import QuartzCore
import Foundation

struct LivePlaybackStream: Decodable {
  let id: String
  let title: String
  let uploaderName: String
  let uploaderURL: String
  let uploaderAvatarURL: String
  let thumbnailURL: String
  let description: String
  let duration: Int64
  let viewCount: Int64
  let likeCount: Int64
  let dislikeCount: Int64
  let uploadDate: String
  let uploaded: Int64
  let uploaderSubscriberCount: Int64
  let uploaderVerified: Bool
  let publishedAt: Int64?
  let startPosition: Int64
  let hlsURL: String
  let videoStreams: [LivePlaybackVideoSource]
  let audioStreams: [LivePlaybackAudioSource]
  let videoOnlyStreams: [LivePlaybackVideoSource]
  let subtitles: [LivePlaybackSubtitle]
  let chapters: [LivePlaybackChapter]
  let sponsorBlockSegments: [LivePlaybackSponsorSegment]
  let relatedStreams: [LiveVideoItem]
  let category: String?
  let isLive: Bool
  let isPostLive: Bool
  let isLiveContent: Bool
  var originalAudioTrackID: String? = nil
  var preferredDefaultAudioTrackID: String? = nil

  var allVideoSources: [LivePlaybackVideoSource] {
    var seen: Set<String> = []
    return (videoOnlyStreams + videoStreams).filter {
      seen.insert($0.selectionID).inserted
    }
  }

  private enum CodingKeys: String, CodingKey {
    case id, title, uploaderName, description, duration, viewCount
    case likeCount, dislikeCount, uploadDate, uploaded
    case uploaderSubscriberCount, uploaderVerified, publishedAt
    case startPosition, videoStreams
    case audioStreams, videoOnlyStreams, subtitles, relatedStreams
    case category, isLive, isPostLive, isLiveContent
    case uploaderURL = "uploaderUrl"
    case uploaderAvatarURL = "uploaderAvatarUrl"
    case thumbnailURL = "thumbnailUrl"
    case hlsURL = "hlsUrl"
    case chapters = "streamSegments"
    case sponsorBlockSegments
    case originalAudioTrackID = "originalAudioTrackId"
    case preferredDefaultAudioTrackID = "preferredDefaultAudioTrackId"
  }
}

struct LivePlaybackPreferences: Equatable {
  var quality: String
  var preferredCodec = "recommended"
  var videoItag: Int?
  var videoSourceID: String?
  var audioTrackID: String?
  var audioSourceID: String?
  var audioOnly: Bool
}

enum LivePlayerImageMode: String, CaseIterable, Identifiable {
  case fit
  case crop
  case stretch

  var id: String { rawValue }

  var title: String {
    switch self {
    case .fit: return "Fit"
    case .crop: return "Crop"
    case .stretch: return "Stretch"
    }
  }

  var videoGravity: AVLayerVideoGravity {
    switch self {
    case .fit: return .resizeAspect
    case .crop: return .resizeAspectFill
    case .stretch: return .resize
    }
  }
}

enum LiveProviderPlayback {
  case separateProgressive(videoURL: URL, audioURL: URL)
  case separateHLS(videoURL: URL, audioURL: URL)
}

struct LivePlaybackPreparation {
  let stream: LivePlaybackStream
  let assetURL: URL?
  let usesAuthenticatedLoader: Bool
  let video: LivePlaybackVideoSource?
  let audio: LivePlaybackAudioSource?
  let providerPlayback: LiveProviderPlayback?
  let subtitles: [LivePlaybackSubtitle]
  let resumeTime: TimeInterval
  let isSABR: Bool
  let audioOnly: Bool
}

enum LivePlaybackFailure: LocalizedError {
  case unsupportedURL
  case noPlayableSource
  case invalidServerResource
  case invalidPlaylist
  case invalidSABRContract
  case sabrSessionFailed
  case sabrSessionTimedOut
  case localPlaybackUnavailable
  case unavailableService

  var errorDescription: String? {
    switch self {
    case .unsupportedURL:
      return "This video URL is not supported by the selected instance."
    case .noPlayableSource:
      return "The instance returned no format that this Apple device can play."
    case .invalidServerResource:
      return "The player rejected a media resource outside the selected instance."
    case .invalidPlaylist:
      return "The instance returned an invalid media playlist."
    case .invalidSABRContract:
      return "The instance returned an inconsistent SABR playback session."
    case .sabrSessionFailed:
      return "The SABR playback session could not provide media."
    case .sabrSessionTimedOut:
      return "The SABR playback session did not become ready in time."
    case .localPlaybackUnavailable:
      return "The secure local playback bridge could not be started."
    case .unavailableService:
      return "Playback is not available in this build."
    }
  }
}
