struct LivePodcastItem: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let title: String
  let url: String
  let thumbnailURL: String
  let uploaderName: String
  let streamCount: Int64
  let playlistType: String

  private enum CodingKeys: String, CodingKey {
    case id
    case title
    case url
    case thumbnailURL = "thumbnailUrl"
    case uploaderName
    case streamCount
    case playlistType
  }
}

struct LivePodcastPage: Decodable, Equatable {
  let channelName: String
  let channelURL: String
  let podcasts: [LivePodcastItem]
  let episodes: [LiveVideoItem]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case channelName
    case channelURL = "channelUrl"
    case podcasts
    case episodes
    case nextPage = "nextpage"
  }
}

struct LivePodcastEpisodesPage: Decodable, Equatable {
  let podcast: LivePodcastItem
  let episodes: [LiveVideoItem]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case podcast, episodes
    case nextPage = "nextpage"
  }
}
