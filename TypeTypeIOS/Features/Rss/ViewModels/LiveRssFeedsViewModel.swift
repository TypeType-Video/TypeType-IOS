import Foundation

@MainActor
final class LiveRssFeedsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var feeds: [LiveRssFeed] = []
  @Published private(set) var subscriptions: [LiveSubscription] = []
  @Published private(set) var errorMessage: String?
  @Published private(set) var busyFeedIDs: Set<String> = []
  @Published var draftName = ""
  @Published var draftIncludesChannels = false
  @Published var draftSelectedChannels: Set<String> = []
  @Published var draftIncludeShorts = true
  @Published var draftIncludeLive = true
  @Published var draftIncludeUpcoming = true
  @Published private(set) var shareURL: URL?

  private let feedService: LiveRssFeedServiceProtocol
  private let subscriptionsService: LiveSubscriptionsServiceProtocol
  private var editingFeedID: String?

  init(
    feedService: LiveRssFeedServiceProtocol,
    subscriptionsService: LiveSubscriptionsServiceProtocol
  ) {
    self.feedService = feedService
    self.subscriptionsService = subscriptionsService
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      async let feedRequest = feedService.feeds()
      async let subscriptionRequest = subscriptionsService.subscriptions()
      let (loadedFeeds, loadedSubscriptions) = try await (
        feedRequest,
        subscriptionRequest
      )
      feeds = loadedFeeds
      subscriptions = loadedSubscriptions
      state = .loaded
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func startCreate() {
    editingFeedID = nil
    draftName = ""
    draftIncludesChannels = false
    draftSelectedChannels = []
    resetContentOptions()
  }

  func startEdit(_ feed: LiveRssFeed) {
    editingFeedID = feed.id
    draftName = feed.name
    draftIncludesChannels = feed.scope == "channels"
    draftSelectedChannels = Set(feed.channelURLs)
    draftIncludeShorts = feed.includeShorts
    draftIncludeLive = feed.includeLive
    draftIncludeUpcoming = feed.includeUpcoming
  }

  func toggleDraftChannel(_ subscription: LiveSubscription) {
    let url = subscription.channelURL
    if draftSelectedChannels.contains(url) {
      draftSelectedChannels.remove(url)
    } else {
      draftSelectedChannels.insert(url)
    }
  }

  func save() async {
    let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      errorMessage = "Enter a feed name."
      return
    }
    let channelURLs = draftSelectedChannels.sorted { $0 < $1 }
    guard !draftIncludesChannels || !channelURLs.isEmpty else {
      errorMessage = "Select at least one subscribed channel."
      return
    }

    let draft = LiveRssFeedDraft(
      name: name,
      scope: draftIncludesChannels ? "channels" : "all",
      channelURLs: channelURLs,
      serviceIDs: [0, 5, 6],
      includeVideos: true,
      includeShorts: draftIncludeShorts,
      includeLive: draftIncludeLive,
      includeUpcoming: draftIncludeUpcoming
    )

    do {
      if let editingFeedID {
        _ = try await feedService.update(id: editingFeedID, draft: draft)
      } else {
        let secret = try await feedService.create(draft: draft)
        shareURL = URL(string: secret.feedURL)
      }
      await reload()
      startCreate()
    } catch {
      errorMessage = Self.message(for: error)
    }
  }

  func setEnabled(_ enabled: Bool, for feed: LiveRssFeed) async {
    guard !busyFeedIDs.contains(feed.id) else { return }
    busyFeedIDs.insert(feed.id)
    defer { busyFeedIDs.remove(feed.id) }
    do {
      let updated = try await feedService.setEnabled(
        id: feed.id,
        enabled: enabled
      )
      replace(updated)
    } catch {
      errorMessage = Self.message(for: error)
    }
  }

  func regenerate(_ feed: LiveRssFeed) async {
    guard !busyFeedIDs.contains(feed.id) else { return }
    busyFeedIDs.insert(feed.id)
    defer { busyFeedIDs.remove(feed.id) }
    do {
      let secret = try await feedService.regenerate(id: feed.id)
      replace(secret.feed)
      shareURL = URL(string: secret.feedURL)
    } catch {
      errorMessage = Self.message(for: error)
    }
  }

  func delete(_ feed: LiveRssFeed) async {
    guard !busyFeedIDs.contains(feed.id) else { return }
    busyFeedIDs.insert(feed.id)
    defer { busyFeedIDs.remove(feed.id) }
    do {
      try await feedService.delete(id: feed.id)
      feeds.removeAll { $0.id == feed.id }
    } catch {
      errorMessage = Self.message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func resetContentOptions() {
    draftIncludeShorts = true
    draftIncludeLive = true
    draftIncludeUpcoming = true
  }

  private func replace(_ feed: LiveRssFeed) {
    guard let index = feeds.firstIndex(where: { $0.id == feed.id }) else {
      feeds.append(feed)
      return
    }
    feeds[index] = feed
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "RSS feeds could not be updated."
  }
}
