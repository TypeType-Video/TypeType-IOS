import Foundation

struct DemoChannelPodcast: Identifiable {
  let id: String
  let title: String
  let creator: String
  let episodeCount: Int
  let artwork: DemoArtwork
}

enum DemoChannelCatalog {
  static func videos(for channel: DemoSearchChannel) -> [DemoVideo] {
    if channel.id == "blender" {
      return blenderVideos
    }

    let firstWord = channel.name.split(separator: " ").first.map(String.init) ?? ""
    let matches = DemoSearchCatalog.videos.filter {
      $0.channel.localizedCaseInsensitiveContains(firstWord)
    }
    return matches.isEmpty ? Array(DemoSearchCatalog.videos.prefix(6)) : matches
  }

  static func playlists(for channel: DemoSearchChannel) -> [DemoPlaylist] {
    switch channel.id {
    case "blender":
      return DemoPlaylistCatalog.initial.filter { $0.id == "open-movies" }
    case "pipepipe":
      return DemoPlaylistCatalog.initial.filter { $0.id == "pipepipe" }
    case "self-hosted":
      return DemoPlaylistCatalog.initial.filter { $0.id == "self-hosted" }
    default:
      return DemoPlaylistCatalog.initial.filter {
        ["calm-design", "favorites"].contains($0.id)
      }
    }
  }

  static func podcasts(for channel: DemoSearchChannel) -> [DemoChannelPodcast] {
    [
      DemoChannelPodcast(
        id: "\(channel.id)-open-playback",
        title: "Open Playback",
        creator: channel.name,
        episodeCount: 8,
        artwork: channel.artwork
      ),
      DemoChannelPodcast(
        id: "\(channel.id)-creator-systems",
        title: "Creator Systems",
        creator: channel.name,
        episodeCount: 12,
        artwork: .typeType
      ),
      DemoChannelPodcast(
        id: "\(channel.id)-media-futures",
        title: "Media Futures",
        creator: channel.name,
        episodeCount: 6,
        artwork: .pipePipe
      ),
    ]
  }

  static func popularityScore(for video: DemoVideo) -> Int {
    popularity[video.id] ?? 0
  }

  private static let popularity: [String: Int] = [
    "big-buck-bunny": 1_200_000,
    "big-buck-restored": 980_000,
    "blender-sintel": 760_000,
    "blender-tears-of-steel": 620_000,
    "blender-elephants-dream": 510_000,
    "blender-sprite-fright": 430_000,
    "blender-cosmos-laundromat": 370_000,
    "blender-spring": 290_000,
  ]

  private static let blenderVideos = [
    DemoMockCatalog.continueWatching[0],
    DemoVideo(
      id: "blender-sintel",
      title: "Sintel — Blender Open Movie",
      channel: "Blender Open Movies",
      metadata: "760K views · 3 months ago",
      duration: "14:48",
      artwork: .television,
      progress: nil
    ),
    DemoVideo(
      id: "blender-tears-of-steel",
      title: "Tears of Steel — Blender Open Movie",
      channel: "Blender Open Movies",
      metadata: "620K views · 6 months ago",
      duration: "12:14",
      artwork: .bird,
      progress: nil
    ),
    DemoVideo(
      id: "blender-elephants-dream",
      title: "Elephants Dream — the first Blender Open Movie",
      channel: "Blender Open Movies",
      metadata: "510K views · last year",
      duration: "10:53",
      artwork: .dog,
      progress: nil
    ),
    DemoMockCatalog.recommendations[3],
    DemoVideo(
      id: "blender-sprite-fright",
      title: "Sprite Fright — Blender Open Movie",
      channel: "Blender Open Movies",
      metadata: "430K views · 2 years ago",
      duration: "10:30",
      artwork: .cat,
      progress: nil
    ),
    DemoVideo(
      id: "blender-cosmos-laundromat",
      title: "Cosmos Laundromat — First Cycle",
      channel: "Blender Open Movies",
      metadata: "370K views · 3 years ago",
      duration: "12:10",
      artwork: .television,
      progress: nil
    ),
    DemoVideo(
      id: "blender-spring",
      title: "Spring — Blender Open Movie",
      channel: "Blender Open Movies",
      metadata: "290K views · 4 years ago",
      duration: "7:44",
      artwork: .bird,
      progress: nil
    ),
  ]
}
