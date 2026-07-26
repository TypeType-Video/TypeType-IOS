import Foundation

struct DemoPlaylist: Identifiable, Hashable {
  let id: String
  let title: String
  let detail: String
  let artwork: DemoArtwork
  let isPublicSaved: Bool
}

enum DemoPlaylistCatalog {
  static let initial = [
    DemoPlaylist(
      id: "favorites",
      title: "Favorites",
      detail: "18 videos",
      artwork: .typeType,
      isPublicSaved: false
    ),
    DemoPlaylist(
      id: "watch-later",
      title: "Watch later",
      detail: "7 videos",
      artwork: .bird,
      isPublicSaved: false
    ),
    DemoPlaylist(
      id: "open-movies",
      title: "Open movie night",
      detail: "12 videos",
      artwork: .television,
      isPublicSaved: false
    ),
    DemoPlaylist(
      id: "self-hosted",
      title: "Self-hosted picks",
      detail: "9 videos",
      artwork: .dog,
      isPublicSaved: false
    ),
    DemoPlaylist(
      id: "pipepipe",
      title: "PipePipe deep dives",
      detail: "6 videos",
      artwork: .pipePipe,
      isPublicSaved: true
    ),
    DemoPlaylist(
      id: "calm-design",
      title: "Calm interface design",
      detail: "24 videos · Open Media",
      artwork: .cat,
      isPublicSaved: true
    ),
    DemoPlaylist(
      id: "open-audio",
      title: "Open audio sessions",
      detail: "14 tracks · Community TV",
      artwork: .bird,
      isPublicSaved: true
    ),
  ]
}
