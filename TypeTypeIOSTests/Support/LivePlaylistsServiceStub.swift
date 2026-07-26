import Foundation
@testable import TypeTypeIOS

final class LivePlaylistsServiceStub: LivePlaylistsServiceProtocol {
  var playlistItems: [LivePlaylist] = []
  var savedItems: [LiveSavedPlaylist] = []
  var publicPages: [LivePublicPlaylistPage] = []
  private(set) var actions: [String] = []

  func playlists() async throws -> [LivePlaylist] {
    playlistItems
  }

  func playlist(id: String) async throws -> LivePlaylist {
    playlistItems.first { $0.id == id }
      ?? LiveLibraryFixtures.playlist(id: id)
  }

  func create(
    name: String,
    description: String
  ) async throws -> LivePlaylist {
    let item = LivePlaylist(
      id: "created",
      name: name,
      description: description
    )
    playlistItems.append(item)
    actions.append("create:\(name)")
    return item
  }

  func update(
    id: String,
    name: String,
    description: String
  ) async throws {
    actions.append("update:\(id):\(name)")
  }

  func delete(id: String) async throws {
    playlistItems.removeAll { $0.id == id }
    actions.append("delete:\(id)")
  }

  func addVideo(
    id: String,
    video: LiveVideoItem
  ) async throws -> LivePlaylistVideo {
    let item = LiveLibraryFixtures.playlistVideo(
      url: video.url,
      title: video.title
    )
    replacePlaylist(id: id) { playlist in
      LivePlaylist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        videos: playlist.videos + [item],
        createdAt: playlist.createdAt
      )
    }
    actions.append("add:\(id):\(video.url)")
    return item
  }

  func removeVideo(id: String, videoURL: String) async throws {
    replacePlaylist(id: id) { playlist in
      LivePlaylist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        videos: playlist.videos.filter { $0.url != videoURL },
        createdAt: playlist.createdAt
      )
    }
    actions.append("remove:\(id):\(videoURL)")
  }

  func reorder(id: String, videoURLs: [String]) async throws {
    actions.append("reorder:\(id):\(videoURLs.joined(separator: ","))")
  }

  func savedPlaylists() async throws -> [LiveSavedPlaylist] {
    savedItems
  }

  func savePublic(url: String) async throws -> LiveSavedPlaylist {
    let saved = LiveLibraryFixtures.saved(id: "created-saved", url: url)
    savedItems.append(saved)
    actions.append("save:\(url)")
    return saved
  }

  func removeSaved(id: String) async throws {
    savedItems.removeAll { $0.id == id }
    actions.append("unsave:\(id)")
  }

  func publicPlaylist(
    url: String,
    nextPage: String?
  ) async throws -> LivePublicPlaylistPage {
    actions.append("public:\(nextPage ?? "first")")
    guard !publicPages.isEmpty else {
      return LivePublicPlaylistPage(
        playlist: LiveLibraryFixtures.publicResult(url: url),
        videos: [],
        nextPage: nil
      )
    }
    return publicPages.removeFirst()
  }

  private func replacePlaylist(
    id: String,
    transform: (LivePlaylist) -> LivePlaylist
  ) {
    guard let index = playlistItems.firstIndex(where: { $0.id == id }) else {
      return
    }
    playlistItems[index] = transform(playlistItems[index])
  }
}
