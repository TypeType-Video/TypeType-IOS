import Foundation

struct LiveSABRPlaybackIndex: Decodable, Equatable {
  let videoID: String
  let sessionID: String
  let live: Bool
  let tracks: Tracks

  struct Tracks: Decodable, Equatable {
    let audio: Track
    let video: Track
  }

  struct Track: Decodable, Equatable {
    let itag: Int
    let maxSegment: Int
    let endSegment: Int64
    let bufferedEndMS: Int64

    private enum CodingKeys: String, CodingKey {
      case itag, maxSegment, endSegment
      case bufferedEndMS = "bufferedEndMs"
    }
  }

  private enum CodingKeys: String, CodingKey {
    case live, tracks
    case videoID = "videoId"
    case sessionID = "session"
  }
}
