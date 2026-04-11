import Foundation

struct HistoryEntry: Decodable, Identifiable {
  let id: String
  let url: String
  let title: String
  let thumbnail: String
  let channelName: String
  let channelUrl: String
  let channelAvatar: String
  let duration: Int64
  let progress: Int64
  let watchedAt: Int64
}
