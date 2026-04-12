import Foundation

@MainActor
final class SubscriptionsViewModel: ObservableObject {
  enum Mode: String, CaseIterable, Identifiable {
    case feed
    case channels
    var id: String { rawValue }
  }

  @Published var mode: Mode = .feed
  @Published private(set) var feedVideos: [HomeVideoItem] = []
  @Published private(set) var channels: [SubscriptionChannel] = []
  @Published private(set) var isLoadingFeed: Bool = false
  @Published private(set) var isLoadingChannels: Bool = false
  @Published private(set) var isLoadingMoreFeed: Bool = false
  @Published private(set) var canLoadMoreFeed: Bool = true
  @Published var errorMessage: String?

  private let service: SubscriptionsServiceProtocol
  private var feedPage: Int = 0

  init(service: SubscriptionsServiceProtocol) {
    self.service = service
  }

  func loadInitial() async {
    if feedVideos.isEmpty {
      await reloadFeed()
    }
    if channels.isEmpty {
      await reloadChannels()
    }
  }

  func refreshCurrent() async {
    switch mode {
    case .feed:
      await reloadFeed()
    case .channels:
      await reloadChannels()
    }
  }

  func reloadFeed() async {
    isLoadingFeed = true
    errorMessage = nil
    do {
      let firstPage = try await service.feed(page: 0, limit: 30)
      feedVideos = firstPage.videos
      feedPage = 1
      canLoadMoreFeed = firstPage.nextPage != nil
      isLoadingFeed = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load subscriptions feed."
      isLoadingFeed = false
    } catch {
      errorMessage = "Unable to load subscriptions feed."
      isLoadingFeed = false
    }
  }

  func loadMoreFeed() async {
    guard canLoadMoreFeed else { return }
    guard !isLoadingFeed, !isLoadingMoreFeed else { return }
    isLoadingMoreFeed = true
    do {
      let page = try await service.feed(page: feedPage, limit: 30)
      feedVideos += page.videos
      feedPage += 1
      canLoadMoreFeed = page.nextPage != nil
      isLoadingMoreFeed = false
    } catch {
      isLoadingMoreFeed = false
    }
  }

  func reloadChannels() async {
    isLoadingChannels = true
    errorMessage = nil
    do {
      channels = try await service.channels()
      isLoadingChannels = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load subscriptions."
      isLoadingChannels = false
    } catch {
      errorMessage = "Unable to load subscriptions."
      isLoadingChannels = false
    }
  }

  func remove(channel: SubscriptionChannel) async {
    do {
      try await service.setSubscription(
        channelURL: channel.channelUrl,
        name: channel.name,
        avatarURL: channel.avatarUrl,
        enabled: false
      )
      channels.removeAll(where: { $0.channelUrl == channel.channelUrl })
    } catch {
      errorMessage = "Unable to unsubscribe right now."
    }
  }
}
