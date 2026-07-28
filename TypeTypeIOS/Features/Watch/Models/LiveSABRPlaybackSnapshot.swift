import Foundation

enum LiveSABRTrackKind: Hashable {
  case audio
  case video
}

struct LiveSABRTrackSnapshot: Equatable {
  let itag: Int
  let mime: String
  let initURL: URL
  let segments: [LiveSABRMediaSegment]

  var startMS: Int64 {
    segments.first?.startMS ?? 0
  }

  var endMS: Int64 {
    guard let last = segments.last else { return 0 }
    return last.startMS + last.durationMS
  }

  func mediaURL(sequence: Int) -> URL? {
    guard sequence > 0,
      var components = URLComponents(
        url: initURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return nil
    }
    let base = components.path.hasSuffix("/init")
      ? String(components.path.dropLast("/init".count))
      : components.path
    components.path = "\(base)/segment/\(sequence)"
    return components.url
  }
}

struct LiveSABRMediaSegment: Equatable, Hashable {
  let url: URL
  let startMS: Int64
  let durationMS: Int64

  var sequence: Int {
    let parts = url.path.split(separator: "/")
    guard let marker = parts.lastIndex(of: "segment"),
      parts.indices.contains(marker + 1)
    else {
      return 0
    }
    return Int(parts[marker + 1]) ?? 0
  }
}

struct LiveSABRPlaybackSnapshot: Equatable {
  let sessionID: String
  let generation: Int64
  let startTimeMS: Int64
  let durationMS: Int64
  let endOfStream: Bool
  let audio: LiveSABRTrackSnapshot
  let video: LiveSABRTrackSnapshot?
  let live: LiveSABRLiveState?
  let index: LiveSABRPlaybackIndex?

  var isIndexedVOD: Bool {
    live?.active != true
      && index?.live != true
      && (index?.tracks.audio.endSegment ?? 0) > 0
      && (video == nil || (index?.tracks.video.endSegment ?? 0) > 0)
  }
}
