import Foundation

@MainActor
final class LiveSubscriptionsViewModel: ObservableObject {
  enum Section: String, CaseIterable, Identifiable {
    case videos
    case channels

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
  }

  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published var section = Section.videos
  @Published private(set) var state = State.idle
  @Published private(set) var videos: [LiveVideoItem] = []
  @Published private(set) var channels: [LiveSubscription] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var groups: [LiveSubscriptionGroup] = []
  @Published var filter = LiveSubscriptionFilter.all

  private let service: LiveSubscriptionsServiceProtocol
  private var nextPage: String?
  private var loadTask: Task<Void, Never>?

  init(service: LiveSubscriptionsServiceProtocol) {
    self.service = service
  }

  deinit {
    loadTask?.cancel()
  }

  var canLoadMore: Bool {
    nextPage?.isEmpty == false
  }

  var visibleVideos: [LiveVideoItem] {
    videos
  }

  var filterLabel: String {
    switch filter {
    case .all:
      return "All subscriptions"
    case .ungrouped:
      return "Ungrouped"
    case let .group(_, name):
      return name
    }
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    loadTask?.cancel()
    state = .loading
    do {
      async let channelRequest = service.subscriptions()
      async let groupRequest = service.groups()
      async let feedRequest = service.feed(
        nextPage: nil,
        filter: filter
      )
      let (loadedChannels, loadedGroups, page) = try await (
        channelRequest,
        groupRequest,
        feedRequest
      )
      try Task.checkCancellation()
      channels = loadedChannels
      groups = loadedGroups
      videos = uniqueVisible(page.videos)
      nextPage = page.nextPage
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let nextPage, !nextPage.isEmpty else {
      return
    }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.feed(
        nextPage: nextPage,
        filter: filter
      )
      let existing = Set(videos.map(\.canonicalID))
      videos.append(
        contentsOf: uniqueVisible(page.videos).filter {
          !existing.contains($0.canonicalID)
        }
      )
      self.nextPage = page.nextPage
    } catch is CancellationError {
      return
    } catch let error as NetworkError {
      if case .statusCode(409, _) = error {
        await reload()
        return
      }
      state = .failed(message(for: error))
    } catch {
      state = .failed(message(for: error))
    }
  }

  func selectFilter(_ newFilter: LiveSubscriptionFilter) async {
    guard filter != newFilter else { return }
    filter = newFilter
    loadTask?.cancel()
    state = .loading
    do {
      let page = try await service.feed(nextPage: nil, filter: filter)
      videos = uniqueVisible(page.videos)
      nextPage = page.nextPage
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func unsubscribe(_ channel: LiveSubscription) async {
    do {
      try await service.unsubscribe(channelURL: channel.channelURL)
      channels.removeAll { $0.id == channel.id }
      await reload()
    } catch {
      state = .failed(message(for: error))
    }
  }

  private func uniqueVisible(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter {
      seen.insert($0.canonicalID).inserted
    }
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Subscriptions could not be loaded."
  }
}
