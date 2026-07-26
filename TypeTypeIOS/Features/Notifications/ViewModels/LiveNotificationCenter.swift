import Foundation

@MainActor
final class LiveNotificationCenter: ObservableObject {
  @Published private(set) var unreadCount = 0

  private let service: LiveNotificationsServiceProtocol
  private var refreshTask: Task<Void, Never>?

  init(service: LiveNotificationsServiceProtocol) {
    self.service = service
  }

  func refresh() async {
    refreshTask?.cancel()
    let task = Task {
      do {
        let value = try await service.unreadCount()
        guard !Task.isCancelled else { return }
        unreadCount = max(value, 0)
      } catch {
        // A badge must never block the authenticated application.
      }
    }
    refreshTask = task
    await task.value
  }

  func synchronize(unreadCount: Int) {
    self.unreadCount = max(unreadCount, 0)
  }

  func clear() {
    refreshTask?.cancel()
    unreadCount = 0
  }
}
