import SwiftUI

extension DemoPlaylistsView {
  func create(_ name: String) {
    withAnimation {
      _ = session.createPlaylist(named: name)
    }
  }

  func select(_ playlist: DemoPlaylist) {
    if isSelecting {
      guard !["favorites", "watch-later"].contains(playlist.id) else { return }
      session.toggle(playlist.id, in: &selectedPlaylistIDs)
    } else {
      selectedPlaylist = playlist
    }
  }

  func confirmDeletion() {
    withAnimation {
      for playlistID in pendingDeletionIDs {
        session.deletePlaylist(playlistID)
      }
      pendingDeletionIDs.removeAll()
      selectedPlaylistIDs.removeAll()
      isSelecting = false
    }
  }

  var deletionTitle: String {
    let count = pendingDeletionIDs.count
    return count == 1 ? "Delete this playlist?" : "Delete \(count) playlists?"
  }

  func displayPlaylist(_ playlist: DemoPlaylist) -> DemoPlaylist {
    let count: Int?
    switch playlist.id {
    case "favorites":
      count = session.favoriteVideoIDs.count
    case "watch-later":
      count = session.watchLaterVideoIDs.count
    default:
      count = session.playlistVideoIDs[playlist.id]?.count
    }
    guard let count else { return playlist }
    return DemoPlaylist(
      id: playlist.id,
      title: playlist.title,
      detail: "\(count) \(count == 1 ? "video" : "videos")",
      artwork: playlist.artwork,
      isPublicSaved: playlist.isPublicSaved
    )
  }

  var savedPublicPlaylists: [DemoPlaylist] {
    session.playlists.filter {
      $0.isPublicSaved && session.savedPublicPlaylistIDs.contains($0.id)
    }
  }
}
