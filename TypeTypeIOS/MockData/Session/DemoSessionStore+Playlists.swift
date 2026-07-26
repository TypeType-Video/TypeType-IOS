import Foundation

extension DemoSessionStore {
  @discardableResult
  func createPlaylist(
    named name: String,
    containing videoID: String? = nil,
    artwork: DemoArtwork = .bird
  ) -> String {
    let nextID = "local-\(UUID().uuidString)"
    playlists.append(
      DemoPlaylist(
        id: nextID,
        title: name,
        detail: "0 videos",
        artwork: artwork,
        isPublicSaved: false
      )
    )
    playlistVideoIDs[nextID] = videoID.map { [$0] } ?? []
    return nextID
  }

  func setVideo(
    _ videoID: String,
    in playlistID: String,
    isIncluded: Bool
  ) {
    switch playlistID {
    case "favorites":
      set(videoID, in: &favoriteVideoIDs, isIncluded: isIncluded)
    case "watch-later":
      set(videoID, in: &watchLaterVideoIDs, isIncluded: isIncluded)
    default:
      var values = playlistVideoIDs[playlistID, default: []]
      set(videoID, in: &values, isIncluded: isIncluded)
      playlistVideoIDs[playlistID] = values
    }
  }

  func renamePlaylist(_ playlistID: String, to title: String) {
    guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else {
      return
    }
    let playlist = playlists[index]
    playlists[index] = DemoPlaylist(
      id: playlist.id,
      title: title,
      detail: playlist.detail,
      artwork: playlist.artwork,
      isPublicSaved: playlist.isPublicSaved
    )
  }

  func deletePlaylist(_ playlistID: String) {
    guard !["favorites", "watch-later"].contains(playlistID) else { return }
    playlists.removeAll { $0.id == playlistID }
    playlistVideoIDs.removeValue(forKey: playlistID)
    savedPublicPlaylistIDs.remove(playlistID)
  }

  func restorePlaylist(_ playlist: DemoPlaylist) {
    guard !playlists.contains(where: { $0.id == playlist.id }) else { return }
    playlists.append(playlist)
    if playlist.isPublicSaved {
      savedPublicPlaylistIDs.insert(playlist.id)
    }
  }
}
