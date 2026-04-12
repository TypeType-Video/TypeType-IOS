import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
  @Published private(set) var unreadCount: Int = 0
  @Published private(set) var items: [NotificationItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published private(set) var canLoadMore: Bool = true
  @Published var errorMessage: String?

  private let service: NotificationsServiceProtocol
  private var nextPageIndex: Int = 0

  init(service: NotificationsServiceProtocol) {
    self.service = service
  }

  func loadInitial() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      async let unread = service.unreadCount()
      async let firstPage = service.notifications(page: 0, limit: 20)

      unreadCount = try await unread
      let page = try await firstPage
      items = page.items
      unreadCount = page.unreadCount
      canLoadMore = page.nextPage != nil
      nextPageIndex = 1
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load notifications."
      isLoading = false
    } catch {
      errorMessage = "Unable to load notifications."
      isLoading = false
    }
  }

  func loadMore() async {
    guard canLoadMore else { return }
    guard !isLoadingMore, !isLoading else { return }
    isLoadingMore = true
    do {
      let page = try await service.notifications(page: nextPageIndex, limit: 20)
      items += page.items
      canLoadMore = page.nextPage != nil
      nextPageIndex += 1
      isLoadingMore = false
    } catch {
      isLoadingMore = false
    }
  }

  func markAllRead() async {
    do {
      try await service.markAllRead()
      unreadCount = 0
    } catch {
      errorMessage = "Unable to mark notifications as read."
    }
  }
}
