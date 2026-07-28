import Foundation

struct LiveSABRPlaybackRequest: Encodable {
  let videoItag: Int
  let audioItag: Int
  let audioTrackID: String?
  let startTimeMS: Int64
  let playerTimeMS: Int64
  let audioOnly: Bool
  let isLive: Bool

  private enum CodingKeys: String, CodingKey {
    case videoItag, audioItag, audioOnly, isLive
    case audioTrackID = "audioTrackId"
    case startTimeMS = "startTimeMs"
    case playerTimeMS = "playerTimeMs"
  }
}

struct LiveSABRPlaybackControl: Decodable, Equatable {
  let sessionID: String
  let videoID: String
  let videoItag: Int
  let audioItag: Int
  let audioTrackID: String?
  let startTimeMS: Int64
  let generation: Int64
  let ready: Bool
  let status: String
  let retryAfterMS: Int64?
  let live: LiveSABRLiveState?

  private enum CodingKeys: String, CodingKey {
    case videoItag, audioItag, generation, ready, status, live
    case sessionID = "sessionId"
    case videoID = "videoId"
    case audioTrackID = "audioTrackId"
    case startTimeMS = "startTimeMs"
    case retryAfterMS = "retryAfterMs"
  }
}

struct LiveSABRWindowRequest: Encodable, Equatable {
  let generation: Int64
  let playerTimeMS: Int64
  let videoItag: Int
  let audioItag: Int
  let audioTrackID: String?
  let playbackRate: Float
  let bufferGoalMS: Int64
  let backBufferMS: Int64
  let bufferedRanges: [LiveSABRBufferedRange]
  let audioOnly: Bool

  private enum CodingKeys: String, CodingKey {
    case generation, videoItag, audioItag, playbackRate
    case bufferedRanges, audioOnly
    case playerTimeMS = "playerTimeMs"
    case audioTrackID = "audioTrackId"
    case bufferGoalMS = "bufferGoalMs"
    case backBufferMS = "backBufferMs"
  }
}

struct LiveSABRPositionRequest: Encodable, Equatable {
  let generation: Int64
  let playerTimeMS: Int64
  let videoItag: Int
  let audioItag: Int
  let audioTrackID: String?
  let playbackRate: Float
  let bufferedRanges: [LiveSABRBufferedRange]
  let audioOnly: Bool

  private enum CodingKeys: String, CodingKey {
    case generation, videoItag, audioItag, playbackRate
    case bufferedRanges, audioOnly
    case playerTimeMS = "playerTimeMs"
    case audioTrackID = "audioTrackId"
  }
}

struct LiveSABRPositionResponse: Decodable, Equatable {
  let sessionID: String
  let generation: Int64
  let playerTimeMS: Int64
  let readerHeadMS: Int64
  let readerTailMS: Int64
  let bufferedEdgeMS: Int64
  let live: LiveSABRLiveState?

  private enum CodingKeys: String, CodingKey {
    case generation, live
    case sessionID = "sessionId"
    case playerTimeMS = "playerTimeMs"
    case readerHeadMS = "readerHeadMs"
    case readerTailMS = "readerTailMs"
    case bufferedEdgeMS = "bufferedEdgeMs"
  }
}

struct LiveSABRBufferedRange: Codable, Equatable {
  let itag: Int
  let startMS: Int64
  let endMS: Int64

  private enum CodingKeys: String, CodingKey {
    case itag
    case startMS = "startMs"
    case endMS = "endMs"
  }
}

struct LiveSABRWindowResponse: Decodable, Equatable {
  let sessionID: String
  let generation: Int64
  let ready: Bool
  let retryAfterMS: Int64?
  let status: String?
  let durationMS: Int64?
  let endOfStream: Bool?
  let audio: LiveSABRWindowTrack?
  let video: LiveSABRWindowTrack?
  let startTimeMS: Int64?
  let playerTimeMS: Int64?
  let readerHeadMS: Int64?
  let readerTailMS: Int64?
  let bufferedEdgeMS: Int64?
  let terminalError: String?
  let recoveryAction: String?
  let retryVideoItags: [Int]?
  let live: LiveSABRLiveState?

  private enum CodingKeys: String, CodingKey {
    case generation, ready, status, endOfStream, audio, video
    case terminalError, recoveryAction, retryVideoItags, live
    case sessionID = "sessionId"
    case retryAfterMS = "retryAfterMs"
    case durationMS = "durationMs"
    case startTimeMS = "startTimeMs"
    case playerTimeMS = "playerTimeMs"
    case readerHeadMS = "readerHeadMs"
    case readerTailMS = "readerTailMs"
    case bufferedEdgeMS = "bufferedEdgeMs"
  }
}

struct LiveSABRWindowTrack: Decodable, Equatable {
  let mime: String
  let initURL: String
  let segments: [LiveSABRWindowSegment]

  private enum CodingKeys: String, CodingKey {
    case mime, segments
    case initURL = "initUrl"
  }
}

struct LiveSABRWindowSegment: Decodable, Equatable, Hashable {
  let url: String
  let startMS: Int64
  let durationMS: Int64

  private enum CodingKeys: String, CodingKey {
    case url
    case startMS = "startMs"
    case durationMS = "durationMs"
  }
}

struct LiveSABRLiveState: Decodable, Equatable {
  let active: Bool
  let postLiveDVR: Bool
  let headSequence: Int64
  let headTimeMS: Int64
  let seekableStartMS: Int64
  let seekableEndMS: Int64
  let atLiveEdge: Bool
  let targetLatencyMS: Int64

  private enum CodingKeys: String, CodingKey {
    case active, headSequence, atLiveEdge
    case postLiveDVR = "postLiveDvr"
    case headTimeMS = "headTimeMs"
    case seekableStartMS = "seekableStartMs"
    case seekableEndMS = "seekableEndMs"
    case targetLatencyMS = "targetLatencyMs"
  }
}
