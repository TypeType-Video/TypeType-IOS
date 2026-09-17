import Foundation

struct LiveRssFeed: Codable, Equatable, Identifiable {
  let id: String
  var name: String
  var scope: String
  var channelURLs: [String]
  var serviceIDs: [Int]
  var includeVideos: Bool
  var includeShorts: Bool
  var includeLive: Bool
  var includeUpcoming: Bool
  var enabled: Bool
  let createdAt: Int64
  var updatedAt: Int64
  var lastUsedAt: Int64?

  private enum CodingKeys: String, CodingKey {
    case id, name, scope
    case channelURLs = "channelUrls"
    case serviceIDs = "serviceIds"
    case includeVideos, includeShorts, includeLive, includeUpcoming
    case enabled, createdAt, updatedAt, lastUsedAt
  }
}

struct LiveRssFeedDraft: Encodable, Equatable {
  var name: String
  var scope: String
  var channelURLs: [String]
  var serviceIDs: [Int]
  var includeVideos: Bool
  var includeShorts: Bool
  var includeLive: Bool
  var includeUpcoming: Bool
}

struct LiveRssFeedSecret: Codable, Equatable {
  let feed: LiveRssFeed
  let feedURL: String

  private enum CodingKeys: String, CodingKey {
    case feed
    case feedURL = "feedUrl"
  }
}
