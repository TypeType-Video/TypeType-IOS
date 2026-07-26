import Foundation

enum DemoSearchCatalog {
  static let recentQueries = [
    "Big Buck Bunny",
    "SABR",
    "TypeType iOS",
  ]

  static let trendingQueries = [
    "Open-source video",
    "Self-hosting",
    "Calm interface design",
    "Playback without tracking",
  ]

  static let videos =
    DemoMockCatalog.continueWatching + DemoMockCatalog.recommendations

  static let channels = DemoSubscriptionCatalog.channels.map { channel in
    DemoSearchChannel(
      id: channel.id,
      name: channel.name,
      handle: channel.handle,
      followers: channel.followers,
      artwork: channel.artwork,
      summary: summary(for: channel.id),
      isVerified: channel.id != "self-hosted",
      isFollowing: channel.id == "blender" || channel.id == "typetype"
    )
  }

  static let playlists = DemoPlaylistCatalog.initial

  static func matchedVideos(for query: String) -> [DemoVideo] {
    filter(videos, query: query) { video in
      [video.title, video.channel, video.metadata]
    }
  }

  static func matchedChannels(for query: String) -> [DemoSearchChannel] {
    filter(channels, query: query) { channel in
      [channel.name, channel.handle, channel.summary]
    }
  }

  static func matchedPlaylists(for query: String) -> [DemoPlaylist] {
    filter(playlists, query: query) { playlist in
      [playlist.title, playlist.detail]
    }
  }

  static func suggestion(for query: String) -> String? {
    let normalized = normalized(query)
    if ["sbar", "sabr playback", "sabr protocol"].contains(normalized) {
      return "SABR"
    }
    if ["big buck buny", "big bunny", "blender bunny"].contains(normalized) {
      return "Big Buck Bunny"
    }
    if ["type type", "typetype video"].contains(normalized) {
      return "TypeType"
    }
    return nil
  }

  static func service(for id: String) -> DemoSearchService {
    if ["discovery", "open-source-weekly", "open-media"].contains(id) {
      return .nicoNico
    }
    if ["typetype-design", "subscriptions", "typetype"].contains(id) {
      return .biliBili
    }
    return .youtube
  }

  static func contentMatches(
    _ filter: DemoSearchContentFilter,
    videoID: String
  ) -> Bool {
    switch filter {
    case .all:
      return true
    case .videos:
      let specializedIDs: Set<String> = [
        "native-ios",
        "discovery",
        "private-home",
        "open-source-weekly",
        "typetype-design",
        "subscriptions",
      ]
      return !specializedIDs.contains(videoID)
    case .live:
      return videoID == "private-home"
    case .music:
      return videoID == "open-source-weekly"
    case .musicVideos:
      return ["open-source-weekly", "typetype-design"].contains(videoID)
    case .albums:
      return videoID == "subscriptions"
    case .musicPlaylists:
      return false
    case .artists:
      return ["typetype-design", "subscriptions"].contains(videoID)
    case .series:
      return ["typetype-design", "subscriptions"].contains(videoID)
    }
  }

  private static func filter<Item>(
    _ items: [Item],
    query: String,
    terms: (Item) -> [String]
  ) -> [Item] {
    let words = normalized(query)
      .split(separator: " ")
      .map(String.init)
    guard !words.isEmpty else { return items }

    return items.filter { item in
      let haystack = terms(item)
        .joined(separator: " ")
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        .lowercased()
      return words.allSatisfy(haystack.contains)
    }
  }

  private static func normalized(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
      .lowercased()
  }

  private static func summary(for id: String) -> String {
    switch id {
    case "blender":
      return "Open movies, production files, and stories from Blender Studio."
    case "typetype":
      return "A private, self-hosted home for the videos you care about."
    case "pipepipe":
      return "Independent Android video client and playback research."
    case "open-media":
      return "Open formats, creator freedom, and sustainable media."
    default:
      return "Practical self-hosting guides for a calmer digital home."
    }
  }
}
