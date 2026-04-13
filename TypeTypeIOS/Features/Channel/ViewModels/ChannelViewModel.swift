import Foundation

@MainActor
final class ChannelViewModel: ObservableObject {
  @Published private(set) var page: ChannelPage?
  @Published private(set) var videos: [HomeVideoItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published private(set) var canLoadMore: Bool = true
  @Published private(set) var isSubscribed: Bool = false
  @Published private(set) var isMutatingSubscription: Bool = false
  @Published var errorMessage: String?

  private let url: String
  private let channelService: ChannelServiceProtocol
  private let subscriptionsService: SubscriptionsServiceProtocol
  private let blockedService: BlockedServiceProtocol
  private var nextPage: String?
  private var blockedChannels: Set<String> = []
  private var blockedVideos: Set<String> = []

  init(
    url: String,
    channelService: ChannelServiceProtocol,
    subscriptionsService: SubscriptionsServiceProtocol,
    blockedService: BlockedServiceProtocol
  ) {
    self.url = url
    self.channelService = channelService
    self.subscriptionsService = subscriptionsService
    self.blockedService = blockedService
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      await loadBlocked()
      async let channelResult = channelService.channel(url: url, nextPage: nil)
      async let channels = subscriptionsService.channels()

      let result = try await channelResult
      let subscriptions = try await channels

      page = result
      videos = BlockedFilter.apply(
        to: result.videos,
        blockedChannels: blockedChannels,
        blockedVideos: blockedVideos
      )
      nextPage = result.nextPage
      canLoadMore = result.nextPage != nil
      isSubscribed = subscriptions.contains(where: { $0.channelUrl == url })
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load channel."
      isLoading = false
    } catch {
      errorMessage = "Unable to load channel."
      isLoading = false
    }
  }

  func loadMore() async {
    guard !isLoadingMore else { return }
    guard canLoadMore else { return }
    guard let nextPage else { return }
    isLoadingMore = true
    do {
      let result = try await channelService.channel(url: url, nextPage: nextPage)
      videos += BlockedFilter.apply(
        to: result.videos,
        blockedChannels: blockedChannels,
        blockedVideos: blockedVideos
      )
      self.nextPage = result.nextPage
      canLoadMore = result.nextPage != nil
      isLoadingMore = false
    } catch {
      isLoadingMore = false
    }
  }

  func toggleSubscription() async {
    guard !isMutatingSubscription else { return }
    guard let page else { return }

    isMutatingSubscription = true
    do {
      try await subscriptionsService.setSubscription(
        channelURL: url,
        name: page.name,
        avatarURL: page.avatarURL,
        enabled: !isSubscribed
      )
      isSubscribed.toggle()
      isMutatingSubscription = false
    } catch {
      errorMessage = "Unable to update subscription."
      isMutatingSubscription = false
    }
  }

  private func loadBlocked() async {
    do {
      async let blockedChannelsReq = blockedService.channels()
      async let blockedVideosReq = blockedService.videos()
      let channels = try await blockedChannelsReq
      let videos = try await blockedVideosReq
      blockedChannels = Set(channels.map(\.url))
      blockedVideos = Set(videos.map(\.url))
    } catch {
      blockedChannels = []
      blockedVideos = []
    }
  }
}
