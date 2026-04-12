import Combine
import Foundation

@MainActor
final class WatchActionsViewModel: ObservableObject {
  @Published private(set) var isFavorite: Bool = false
  @Published private(set) var isWatchLater: Bool = false
  @Published private(set) var isSubscribed: Bool = false
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isMutating: Bool = false
  @Published private(set) var playlists: [PlaylistSummary] = []
  @Published private(set) var playlistIDsContainingVideo: Set<String> = []
  @Published var message: String?

  private let videoURL: String
  private let service: WatchActionsServiceProtocol
  private let libraryService: LibraryServiceProtocol
  private var stream: WatchStream?

  init(videoURL: String, service: WatchActionsServiceProtocol, libraryService: LibraryServiceProtocol) {
    self.videoURL = videoURL
    self.service = service
    self.libraryService = libraryService
  }

  func prepare(stream: WatchStream) {
    self.stream = stream
  }

  func refresh() async {
    guard let stream else { return }
    isLoading = true
    do {
      let state = try await service.state(videoURL: videoURL, channelURL: stream.uploaderUrl)
      isFavorite = state.isFavorite
      isWatchLater = state.isWatchLater
      isSubscribed = state.isSubscribed
      do {
        let fetchedPlaylists = try await libraryService.playlists()
        playlists = fetchedPlaylists
        playlistIDsContainingVideo = Set(
          fetchedPlaylists
            .filter { playlist in
              playlist.videos.contains(where: { $0.url == videoURL })
            }
            .map(\.id)
        )
      } catch {
        playlists = []
        playlistIDsContainingVideo = []
      }
      isLoading = false
    } catch {
      isLoading = false
      message = "Unable to sync actions."
    }
  }

  func toggleFavorite() async {
    guard !isMutating else { return }
    isMutating = true
    do {
      try await service.setFavorite(videoURL: videoURL, enabled: !isFavorite)
      isFavorite.toggle()
      message = isFavorite ? "Added to favorites" : "Removed from favorites"
      isMutating = false
    } catch {
      message = "Unable to update favorite"
      isMutating = false
    }
  }

  func toggleWatchLater() async {
    guard !isMutating else { return }
    guard let stream else { return }
    isMutating = true

    let payload = WatchLaterCreatePayload(
      url: videoURL,
      title: stream.title,
      thumbnail: stream.thumbnailUrl,
      duration: stream.duration
    )

    do {
      try await service.setWatchLater(payload, enabled: !isWatchLater)
      isWatchLater.toggle()
      message = isWatchLater ? "Saved to watch later" : "Removed from watch later"
      isMutating = false
    } catch {
      message = "Unable to update watch later"
      isMutating = false
    }
  }

  func toggleSubscription() async {
    guard !isMutating else { return }
    guard let stream else { return }
    guard !stream.uploaderUrl.isEmpty else { return }
    isMutating = true

    let payload = SubscriptionCreatePayload(
      channelUrl: stream.uploaderUrl,
      name: stream.uploaderName,
      avatarUrl: stream.uploaderAvatarUrl
    )

    do {
      try await service.setSubscription(payload, enabled: !isSubscribed)
      isSubscribed.toggle()
      message = isSubscribed ? "Subscribed" : "Unsubscribed"
      isMutating = false
    } catch {
      message = "Unable to update subscription"
      isMutating = false
    }
  }

  func togglePlaylist(playlistID: String) async {
    guard !isMutating else { return }
    guard let stream else { return }
    isMutating = true
    do {
      if playlistIDsContainingVideo.contains(playlistID) {
        try await libraryService.removeVideo(from: playlistID, videoURL: videoURL)
        playlistIDsContainingVideo.remove(playlistID)
        message = "Removed from playlist"
      } else {
        let payload = PlaylistVideoCreatePayload(
          url: videoURL,
          title: stream.title,
          thumbnail: stream.thumbnailUrl,
          duration: stream.duration
        )
        _ = try await libraryService.addVideo(to: playlistID, video: payload)
        playlistIDsContainingVideo.insert(playlistID)
        message = "Saved to playlist"
      }
      isMutating = false
    } catch {
      message = "Unable to update playlist"
      isMutating = false
    }
  }

  func createPlaylistAndAdd() async {
    guard !isMutating else { return }
    guard let stream else { return }
    isMutating = true
    do {
      let created = try await libraryService.createPlaylist(name: "Favorites", description: "")
      let payload = PlaylistVideoCreatePayload(
        url: videoURL,
        title: stream.title,
        thumbnail: stream.thumbnailUrl,
        duration: stream.duration
      )
      _ = try await libraryService.addVideo(to: created.id, video: payload)
      playlists.insert(created, at: 0)
      playlistIDsContainingVideo.insert(created.id)
      message = "Saved to \(created.name)"
      isMutating = false
    } catch {
      message = "Unable to create playlist"
      isMutating = false
    }
  }
}
