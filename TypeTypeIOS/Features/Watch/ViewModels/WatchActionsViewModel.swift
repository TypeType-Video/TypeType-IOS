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
  @Published private(set) var isVideoBlocked: Bool = false
  @Published private(set) var isChannelBlocked: Bool = false
  @Published var message: String?

  private let videoURL: String
  private let service: WatchActionsServiceProtocol
  private let libraryService: LibraryServiceProtocol
  private let blockedService: BlockedServiceProtocol
  private var stream: WatchStream?

  init(
    videoURL: String,
    service: WatchActionsServiceProtocol,
    libraryService: LibraryServiceProtocol,
    blockedService: BlockedServiceProtocol
  ) {
    self.videoURL = videoURL
    self.service = service
    self.libraryService = libraryService
    self.blockedService = blockedService
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

      do {
        async let blockedVideosReq = blockedService.videos()
        async let blockedChannelsReq = blockedService.channels()
        let blockedVideos = try await blockedVideosReq
        let blockedChannels = try await blockedChannelsReq
        isVideoBlocked = blockedVideos.contains(where: { $0.url == videoURL })
        isChannelBlocked = blockedChannels.contains(where: { $0.url == stream.uploaderUrl })
      } catch {
        isVideoBlocked = false
        isChannelBlocked = false
      }

      isLoading = false
    } catch {
      isLoading = false
      message = "Unable to sync actions."
    }
  }

  var hasChannel: Bool {
    guard let stream else { return false }
    return !stream.uploaderUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

  func toggleVideoBlocked() async {
    guard !isMutating else { return }
    isMutating = true
    do {
      if isVideoBlocked {
        try await blockedService.removeVideo(url: videoURL)
        isVideoBlocked = false
        message = "Video unblocked"
      } else {
        try await blockedService.addVideo(url: videoURL)
        isVideoBlocked = true
        message = "Video blocked"
      }
      isMutating = false
    } catch {
      message = "Unable to update blocked video"
      isMutating = false
    }
  }

  func toggleChannelBlocked() async {
    guard !isMutating else { return }
    guard let stream else { return }
    guard !stream.uploaderUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    isMutating = true
    do {
      if isChannelBlocked {
        try await blockedService.removeChannel(url: stream.uploaderUrl)
        isChannelBlocked = false
        message = "Channel unblocked"
      } else {
        try await blockedService.addChannel(
          url: stream.uploaderUrl,
          name: stream.uploaderName,
          thumbnailUrl: stream.uploaderAvatarUrl
        )
        isChannelBlocked = true
        message = "Channel blocked"
      }
      isMutating = false
    } catch {
      message = "Unable to update blocked channel"
      isMutating = false
    }
  }
}
