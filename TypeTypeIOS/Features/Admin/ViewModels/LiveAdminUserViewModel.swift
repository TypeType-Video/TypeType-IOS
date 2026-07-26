import Foundation

@MainActor
final class LiveAdminUserViewModel: ObservableObject {
  @Published private(set) var user: LiveAdminUser
  @Published var email: String
  @Published var name: String
  @Published var role: String
  @Published private(set) var isBusy = false
  @Published private(set) var resetToken: String?
  @Published private(set) var message: String?
  @Published private(set) var errorMessage: String?

  private let service: LiveAdminServiceProtocol

  init(user: LiveAdminUser, service: LiveAdminServiceProtocol) {
    self.user = user
    email = user.email
    name = user.name
    role = user.role
    self.service = service
  }

  func saveIdentity() async {
    await perform(message: "Identity updated") {
      try await service.updateIdentity(
        id: user.id,
        email: email,
        name: name
      )
    }
  }

  func saveRole() async {
    await perform(message: "Role updated") {
      try await service.updateRole(id: user.id, role: role)
    }
  }

  func toggleSuspended() async {
    let next = !user.suspended
    await perform(message: next ? "User suspended" : "User restored") {
      try await service.setSuspended(id: user.id, suspended: next)
      user = replacingSuspended(next)
    }
  }

  func generateResetToken() async {
    await perform(message: "Reset token created") {
      resetToken = try await service.createResetToken(id: user.id)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func perform(
    message: String,
    operation: () async throws -> Void
  ) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      try await operation()
      self.message = message
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription
        ?? "The user could not be updated."
    }
  }

  private func replacingSuspended(_ suspended: Bool) -> LiveAdminUser {
    LiveAdminUser(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      publicUsername: user.publicUsername,
      bio: user.bio,
      avatarURL: user.avatarURL,
      avatarType: user.avatarType,
      avatarCode: user.avatarCode,
      suspended: suspended,
      verified: user.verified,
      accessMode: user.accessMode,
      createdAt: user.createdAt
    )
  }
}
