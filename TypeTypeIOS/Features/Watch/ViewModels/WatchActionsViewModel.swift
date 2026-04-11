import Combine
import Foundation

@MainActor
final class WatchActionsViewModel: ObservableObject {
  @Published private(set) var isFavorite: Bool = false
  @Published private(set) var isWatchLater: Bool = false
  @Published private(set) var isSubscribed: Bool = false
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isMutating: Bool = false
  @Published var message: String?

  private let videoURL: String
  private let service: WatchActionsServiceProtocol
  private var stream: WatchStream?

  init(videoURL: String, service: WatchActionsServiceProtocol) {
    self.videoURL = videoURL
    self.service = service
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
}
