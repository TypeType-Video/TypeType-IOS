import Foundation

@MainActor
final class LiveAdminBugReportsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var reports: [LiveAdminBugReport] = []
  @Published private(set) var total: Int64 = 0
  @Published var status = ""
  @Published var category = ""
  @Published private(set) var page = 1
  @Published private(set) var isLoadingMore = false

  private let service: LiveBugReportsServiceProtocol
  private let pageSize = 30

  init(service: LiveBugReportsServiceProtocol) {
    self.service = service
  }

  var canLoadMore: Bool {
    Int64(reports.count) < total
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      let result = try await request(page: 1)
      reports = result.items
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
      let result = try await request(page: next)
      let existing = Set(reports.map(\.id))
      reports.append(contentsOf: result.items.filter {
        !existing.contains($0.id)
      })
      total = result.total
      page = next
    } catch {
      state = .failed(text(for: error))
    }
  }

  private func request(
    page: Int
  ) async throws -> LiveAdminBugReportsPage {
    try await service.reports(
      page: page,
      limit: pageSize,
      status: status.isEmpty ? nil : status,
      category: category.isEmpty ? nil : category
    )
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Bug reports could not be loaded."
  }
}
