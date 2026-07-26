import Foundation

struct LiveAdminNowPlaying: Decodable, Equatable {
  let videoURL: String
  let title: String
  let thumbnail: String?
  let channelName: String?
  let positionMilliseconds: Int64
  let durationMilliseconds: Int64?
  let paused: Bool
  let updatedAt: Int64

  private enum CodingKeys: String, CodingKey {
    case videoURL = "videoUrl"
    case title, thumbnail, channelName
    case positionMilliseconds = "positionMs"
    case durationMilliseconds = "durationMs"
    case paused, updatedAt
  }
}

struct LiveAdminSession: Decodable, Equatable, Identifiable {
  let id: String
  let userID: String?
  let username: String?
  let clientName: String?
  let clientVersion: String?
  let deviceID: String?
  let deviceName: String?
  let deviceType: String?
  let userAgent: String?
  let remoteAddress: String?
  let lastActivityAt: Int64
  let lastPlaybackAt: Int64?
  let nowPlaying: LiveAdminNowPlaying?

  private enum CodingKeys: String, CodingKey {
    case id
    case userID = "userId"
    case username, clientName, clientVersion
    case deviceID = "deviceId"
    case deviceName, deviceType, userAgent, remoteAddress
    case lastActivityAt, lastPlaybackAt, nowPlaying
  }
}
