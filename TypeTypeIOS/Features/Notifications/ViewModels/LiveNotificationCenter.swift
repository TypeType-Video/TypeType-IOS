import Foundation

@MainActor
final class LiveNotificationCenter: ObservableObject {
  @Published private(set) var unreadCount = 0
  @Published private(set) var isPolling = false

  private let service: LiveNotificationsServiceProtocol
  private var refreshTask: Task<Void, Never>?
  private var pollingTask: Task<Void, Never>?
  private var pollingGeneration = 0

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

  func startPolling(interval: Duration = .seconds(60)) {
    guard pollingTask == nil else { return }
    isPolling = true
    pollingTask = Task { [weak self] in
      guard let self else { return }
      await refresh()
      while !Task.isCancelled {
        try? await Task.sleep(for: interval)
        guard !Task.isCancelled else { break }
        await refresh()
      }
      isPolling = false
      pollingTask = nil
    }
  }

  func stopPolling() {
    pollingTask?.cancel()
    pollingTask = nil
    isPolling = false
    pollingGeneration += 1
  }

  func synchronize(unreadCount: Int) {
    self.unreadCount = max(unreadCount, 0)
  }

  func clear() {
    refreshTask?.cancel()
    stopPolling()
    pollingGeneration += 1
    unreadCount = 0
  }
}
