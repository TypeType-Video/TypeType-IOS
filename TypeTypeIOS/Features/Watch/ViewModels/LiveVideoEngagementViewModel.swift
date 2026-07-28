import Combine
import Foundation

@MainActor
final class LiveVideoEngagementViewModel: ObservableObject {
  @Published private(set) var isSubscribed = false
  @Published private(set) var isLoading = false
  @Published private(set) var isChanging = false
  @Published private(set) var message: String?

  let video: LiveVideoItem
  let allowsSubscription: Bool
  private let service: LiveSubscriptionsServiceProtocol
  private var didPrepare = false

  init(
    video: LiveVideoItem,
    allowsSubscription: Bool,
    service: LiveSubscriptionsServiceProtocol
  ) {
    self.video = video
    self.allowsSubscription = allowsSubscription
    self.service = service
  }

  var canSubscribe: Bool {
    allowsSubscription && !video.uploaderURL.isEmpty
  }

  func prepare() async {
    guard canSubscribe, !didPrepare else { return }
    didPrepare = true
    isLoading = true
    defer { isLoading = false }
    do {
      let subscriptions = try await service.subscriptions()
      isSubscribed = subscriptions.contains {
        normalized($0.channelURL) == normalized(video.uploaderURL)
      }
    } catch {
      didPrepare = false
    }
  }

  func toggleSubscription() async {
    guard canSubscribe, !isChanging else { return }
    isChanging = true
    message = nil
    defer { isChanging = false }
    do {
      if isSubscribed {
        try await service.unsubscribe(channelURL: video.uploaderURL)
        isSubscribed = false
        message = "Unsubscribed from \(video.uploaderName)."
      } else {
        _ = try await service.subscribe(
          channelURL: video.uploaderURL,
          name: video.uploaderName,
          avatarURL: video.uploaderAvatarURL
        )
        isSubscribed = true
        message = "Subscribed to \(video.uploaderName)."
      }
    } catch {
      message = (error as? LocalizedError)?.errorDescription
        ?? "Subscription could not be updated."
    }
  }

  private func normalized(_ value: String) -> String {
    value.trimmingCharacters(
      in: CharacterSet(charactersIn: "/")
    ).lowercased()
  }
}
