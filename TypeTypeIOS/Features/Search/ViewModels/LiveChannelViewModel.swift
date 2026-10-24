import Combine
import Foundation

@MainActor
final class LiveChannelViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
  }

  @Published var state = State.idle
  @Published var channel: LiveChannelPage?
  @Published var videos: [LiveVideoItem] = []
  @Published var playlists: [LivePlaylistResult] = []
  @Published var podcasts: [LivePodcastItem] = []
  @Published var selectedTab = LiveChannelTab.videos
  @Published var sort = LiveChannelSort.latest
  @Published var query = ""
  @Published var submittedQuery = ""
  @Published var isLoadingMore = false
  @Published var canLoadMore = false
  @Published var isSubscribed = false
  @Published var isChangingSubscription = false
  @Published var subscriptionError: String?
  @Published var isNotificationsAvailable = false
  @Published var isNotificationsEnabled = false
  @Published var isChangingNotifications = false
  @Published var isLoadingPodcasts = false
  @Published var canLoadMorePodcasts = false

  let channelURL: String
  let channelService: LiveChannelServiceProtocol
  let subscriptionsService: LiveSubscriptionsServiceProtocol
  let pushNotificationsService: LivePushNotificationsServiceProtocol?
  let pushNotificationsEnabled: Bool
  var requestID = UUID()
  var nextPage: String?
  var podcastNextPage: String?
  var loadTask: Task<LiveChannelPage, Error>?
  var paginationTask: Task<LiveChannelPage, Error>?

  init(
    channelURL: String,
    channelService: LiveChannelServiceProtocol,
    subscriptionsService: LiveSubscriptionsServiceProtocol,
    pushNotificationsService: LivePushNotificationsServiceProtocol? = nil,
    pushNotificationsEnabled: Bool = false
  ) {
    // Every entry point funnels through here: canonicalize once so
    // subscriptions rows, video metadata, search rows and deep links all
    // address the channel in the same form the server canonicalizes to.
    self.channelURL = LiveChannelURLCanonicalizer.canonicalize(channelURL)
    self.channelService = channelService
    self.subscriptionsService = subscriptionsService
    self.pushNotificationsService = pushNotificationsService
    self.pushNotificationsEnabled = pushNotificationsEnabled
  }

  func loadIfNeeded() async {
    guard state == .idle else { return }
    await refreshSubscriptionStatus()
    async let notifications: Void = refreshNotificationPreference()
    async let podcasts: Void = loadPodcasts()
    async let channel: Void = reloadChannel()
    _ = await (notifications, podcasts, channel)
  }

  func reloadChannel() async {
    let currentRequest = UUID()
    requestID = currentRequest
    loadTask?.cancel()
    paginationTask?.cancel()
    state = .loading
    canLoadMore = false
    nextPage = nil
    let requestURL = LiveChannelRequestURLBuilder.build(
      channelURL: channelURL,
      query: submittedQuery,
      tab: selectedTab
    )
    let task = Task {
      try await channelService.channel(
        url: requestURL,
        nextPage: nil,
        sort: sort
      )
    }
    loadTask = task
    do {
      let page = try await task.value
      guard requestID == currentRequest, !Task.isCancelled else {
        return
      }
      channel = page
      videos = Self.uniqueVideos(page.videos)
      nextPage = page.nextPage
      canLoadMore = page.nextPage?.isEmpty == false
      state = videos.isEmpty ? .empty : .loaded
    } catch is CancellationError {
      return
    } catch {
      guard requestID == currentRequest else { return }
      state = .failed(Self.message(for: error))
    }
  }

  func loadMore() async {
    if selectedTab == .playlists {
      await loadMorePlaylists()
      return
    }
    guard canLoadMore, !isLoadingMore else { return }
    guard let nextPage, !nextPage.isEmpty else { return }
    let currentRequest = requestID
    isLoadingMore = true
    let requestURL = LiveChannelRequestURLBuilder.build(
      channelURL: channelURL,
      query: submittedQuery,
      tab: selectedTab
    )
    let task = Task {
      try await channelService.channel(
        url: requestURL,
        nextPage: nextPage,
        sort: sort
      )
    }
    paginationTask = task
    defer {
      if requestID == currentRequest {
        isLoadingMore = false
      }
    }
    do {
      let page = try await task.value
      guard requestID == currentRequest, !Task.isCancelled else {
        return
      }
      videos = Self.uniqueVideos(videos + page.videos)
      self.nextPage = page.nextPage
      canLoadMore = page.nextPage?.isEmpty == false
      state = videos.isEmpty ? .empty : .loaded
    } catch {
      guard requestID == currentRequest else { return }
      canLoadMore = true
    }
  }

  func selectTab(_ tab: LiveChannelTab) async {
    guard selectedTab != tab else { return }
    selectedTab = tab
    query = ""
    submittedQuery = ""
    if tab == .playlists {
      await loadPlaylists()
    } else {
      await reloadChannel()
    }
  }

  func selectSort(_ nextSort: LiveChannelSort) async {
    guard sort != nextSort else { return }
    sort = nextSort
    guard selectedTab != .playlists else { return }
    await reloadChannel()
  }

  func submitChannelSearch() async {
    let term = query.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard term != submittedQuery else { return }
    submittedQuery = term
    selectedTab = .videos
    await reloadChannel()
  }

  func clearChannelSearch() async {
    query = ""
    guard !submittedQuery.isEmpty else { return }
    submittedQuery = ""
    await reloadChannel()
  }

  static func uniqueVideos(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter {
      seen.insert($0.canonicalID).inserted
    }
  }

  static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "This channel could not be loaded."
  }
}
