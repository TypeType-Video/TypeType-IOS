import Combine
import Foundation

@MainActor
final class AdminUsersViewModel: ObservableObject {
  @Published private(set) var users: [AdminUser] = []
  @Published private(set) var page: Int = 1
  @Published private(set) var total: Int = 0
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published var errorMessage: String?
  @Published var tokenMessage: String?

  private let service: AdminServiceProtocol
  private let pageSize = 25

  init(service: AdminServiceProtocol) {
    self.service = service
  }

  var canLoadMore: Bool {
    users.count < total && !isLoading && !isLoadingMore
  }

  func reload() async {
    isLoading = true
    errorMessage = nil
    do {
      let response = try await service.users(page: 1, limit: pageSize)
      users = response.items
      page = response.page
      total = response.total
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load users."
      isLoading = false
    } catch {
      errorMessage = "Unable to load users."
      isLoading = false
    }
  }

  func loadMore() async {
    guard canLoadMore else { return }
    isLoadingMore = true
    do {
      let response = try await service.users(page: page + 1, limit: pageSize)
      users.append(contentsOf: response.items)
      page = response.page
      total = response.total
      isLoadingMore = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load more users."
      isLoadingMore = false
    } catch {
      errorMessage = "Unable to load more users."
      isLoadingMore = false
    }
  }

  func changeRole(user: AdminUser, to role: AdminRole) async {
    tokenMessage = nil
    do {
      try await service.setRole(userID: user.id, role: role)
      await reload()
    } catch {
      errorMessage = "Unable to update role."
    }
  }

  func toggleSuspension(for user: AdminUser) async {
    tokenMessage = nil
    do {
      try await service.setSuspended(userID: user.id, suspended: !user.suspended)
      await reload()
    } catch {
      errorMessage = "Unable to update suspension."
    }
  }

  func createResetToken(for user: AdminUser) async {
    do {
      let token = try await service.resetToken(userID: user.id)
      tokenMessage = "\(user.email): \(token.resetToken)"
    } catch {
      errorMessage = "Unable to generate reset token."
    }
  }
}
