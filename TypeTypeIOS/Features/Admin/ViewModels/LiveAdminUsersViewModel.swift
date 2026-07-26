import Foundation

@MainActor
final class LiveAdminUsersViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var users: [LiveAdminUser] = []
  @Published private(set) var total: Int64 = 0
  @Published private(set) var page = 1
  @Published private(set) var isLoadingMore = false

  private let service: LiveAdminServiceProtocol
  private let pageSize = 50

  init(service: LiveAdminServiceProtocol) {
    self.service = service
  }

  var canLoadMore: Bool {
    Int64(users.count) < total
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      let result = try await service.users(page: 1, limit: pageSize)
      users = result.items
      total = result.total
      page = 1
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func loadMore() async {
    guard canLoadMore, !isLoadingMore else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let next = page + 1
      let result = try await service.users(
        page: next,
        limit: pageSize
      )
      let existing = Set(users.map(\.id))
      users.append(contentsOf: result.items.filter {
        !existing.contains($0.id)
      })
      total = result.total
      page = next
    } catch {
      state = .failed(text(for: error))
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Users could not be loaded."
  }
}
