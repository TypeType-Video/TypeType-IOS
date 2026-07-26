import Foundation

@MainActor
final class LiveNotificationsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var items: [LiveNotification] = []
  @Published private(set) var unreadCount = 0
  @Published private(set) var isLoadingMore = false
  @Published private(set) var isMarkingRead = false
  @Published private(set) var errorMessage: String?

  private let service: LiveNotificationsServiceProtocol
  private let notificationCenter: LiveNotificationCenter
  private var nextPage: Int?

  init(
    service: LiveNotificationsServiceProtocol,
    notificationCenter: LiveNotificationCenter
  ) {
    self.service = service
    self.notificationCenter = notificationCenter
  }

  var canLoadMore: Bool {
    nextPage != nil
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      let page = try await service.notifications(page: 0, limit: 20)
      items = unique(page.items)
      unreadCount = page.unreadCount
      notificationCenter.synchronize(unreadCount: page.unreadCount)
      nextPage = page.nextPage
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let nextPage else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.notifications(
        page: nextPage,
        limit: 20
      )
      let existing = Set(items.map(\.id))
      items.append(contentsOf: page.items.filter {
        !existing.contains($0.id)
      })
      unreadCount = page.unreadCount
      notificationCenter.synchronize(unreadCount: page.unreadCount)
      self.nextPage = page.nextPage
    } catch {
      errorMessage = text(for: error)
    }
  }

  func markAllRead() async {
    guard !isMarkingRead, unreadCount > 0 else { return }
    isMarkingRead = true
    defer { isMarkingRead = false }
    do {
      unreadCount = try await service.markAllRead().unreadCount
      notificationCenter.synchronize(unreadCount: unreadCount)
    } catch {
      errorMessage = text(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func unique(
    _ candidates: [LiveNotification]
  ) -> [LiveNotification] {
    var seen: Set<String> = []
    return candidates.filter { seen.insert($0.id).inserted }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Notifications could not be loaded."
  }
}
