import Foundation

@MainActor
final class LivePrivacyDataViewModel: ObservableObject {
  enum State: Equatable {
    case idle, loading, loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var historyCount = 0
  @Published private(set) var searchHistoryCount = 0
  @Published private(set) var subscriptions: [LiveSubscription] = []
  @Published private(set) var isBusy = false
  @Published private(set) var message: String?

  private let history: LiveHistoryServiceProtocol
  private let searchHistory: LiveSearchHistoryServiceProtocol
  private let subscriptionService: LiveSubscriptionsServiceProtocol

  init(
    history: LiveHistoryServiceProtocol,
    searchHistory: LiveSearchHistoryServiceProtocol,
    subscriptions: LiveSubscriptionsServiceProtocol
  ) {
    self.history = history
    self.searchHistory = searchHistory
    subscriptionService = subscriptions
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      async let historyItems = history.history(
        query: nil,
        from: nil,
        to: nil,
        limit: 1_000,
        offset: 0
      )
      async let searchItems = searchHistory.history(
        page: 1,
        limit: 100
      )
      async let subscriptionItems = subscriptionService.subscriptions()
      historyCount = try await historyItems.count
      searchHistoryCount = try await searchItems.count
      subscriptions = try await subscriptionItems
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func clearHistory() async {
    await perform(success: "Watch history cleared.") {
      try await history.clear()
    }
  }

  func clearSearchHistory() async {
    await perform(success: "Search history cleared.") {
      try await searchHistory.clear()
    }
  }

  func unsubscribeAll() async {
    await perform(success: "All channels unsubscribed.") {
      for subscription in subscriptions {
        try Task.checkCancellation()
        try await subscriptionService.unsubscribe(
          channelURL: subscription.channelURL
        )
      }
    }
  }

  private func perform(
    success: String,
    operation: () async throws -> Void
  ) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      try await operation()
      message = success
      await reload()
    } catch {
      state = .failed(text(for: error))
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Stored data could not be updated."
  }
}
