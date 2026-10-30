import Foundation

extension LiveHomeViewModel {
  static func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask {
        try await operation()
      }
      group.addTask {
        try await Task.sleep(for: .seconds(seconds))
        throw NetworkError.transport
      }
      guard let first = try await group.next() else {
        throw NetworkError.transport
      }
      group.cancelAll()
      return first
    }
  }

  static func recommendationsTask(
    service: HomeFeedServiceProtocol,
    serviceID: Int,
    limit: Int,
    hidden: Bool
  ) -> Task<HomeRecommendationsPage, Error> {
    Task {
      guard !hidden else { return HomeRecommendationsPage(items: [], nextCursor: nil, hasMore: false) }
      return try await withTimeout(seconds: 15) {
        try await service.recommendations(serviceID: serviceID, intent: "auto", limit: limit, cursor: nil)
      }
    }
  }

  // Continue watching is optional on the home page: a failed or slow history request leaves the row empty.
  static func continueWatchingTask(
    historyService: LiveHistoryServiceProtocol,
    hidden: Bool
  ) -> Task<[LiveHistoryItem], Never> {
    Task {
      guard !hidden else { return [] }
      return (try? await withTimeout(seconds: 8) {
        try await historyService.history(query: nil, from: nil, to: nil, limit: 30, offset: 0)
      }) ?? []
    }
  }
}
