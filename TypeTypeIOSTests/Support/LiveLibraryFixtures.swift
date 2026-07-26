import Foundation
@testable import TypeTypeIOS

enum LiveLibraryFixtures {
  static func favorite(
    url: String = "https://video.test/favorite",
    title: String = "Favorite",
    savedAt: Int64 = 20
  ) -> LiveFavoriteItem {
    LiveFavoriteItem(
      videoURL: url,
      favoritedAt: savedAt,
      title: title,
      duration: 120,
      channelName: "TypeType"
    )
  }

  static func watchLater(
    url: String = "https://video.test/later",
    title: String = "Watch later",
    savedAt: Int64 = 10
  ) -> LiveWatchLaterItem {
    LiveWatchLaterItem(
      url: url,
      title: title,
      duration: 90,
      addedAt: savedAt,
      channelName: "TypeType"
    )
  }

  static func playlist(
    id: String = "playlist-1",
    name: String = "Native",
    videos: [LivePlaylistVideo] = []
  ) -> LivePlaylist {
    LivePlaylist(
      id: id,
      name: name,
      videos: videos,
      createdAt: 10
    )
  }

  static func playlistVideo(
    url: String = "https://video.test/playlist",
    title: String = "Playlist video",
    position: Int = 0
  ) -> LivePlaylistVideo {
    LivePlaylistVideo(
      id: url,
      url: url,
      title: title,
      thumbnail: "",
      duration: 60,
      position: position,
      channelName: "TypeType"
    )
  }

  static func saved(
    id: String = "saved-1",
    url: String = "https://video.test/public-list"
  ) -> LiveSavedPlaylist {
    LiveSavedPlaylist(
      id: id,
      publicPlaylistID: "public-1",
      url: url,
      title: "Public",
      thumbnailURL: "",
      uploaderName: "TypeType",
      streamCount: 2,
      playlistType: "normal",
      savedAt: 10
    )
  }

  static func publicResult(
    url: String = "https://video.test/public-list"
  ) -> LivePlaylistResult {
    LivePlaylistResult(
      id: "public-1",
      title: "Public",
      url: url,
      thumbnailURL: "",
      uploaderName: "TypeType",
      streamCount: 2,
      playlistType: "normal"
    )
  }
}
