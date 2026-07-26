import Foundation

@MainActor
final class LiveAccountIdentityViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published var email = ""
  @Published var name = ""
  @Published var currentPassword = ""
  @Published private(set) var managedByOIDC = false
  @Published private(set) var isSaving = false
  @Published private(set) var message: String?
  @Published private(set) var errorMessage: String?

  private let service: LiveProfileServiceProtocol

  init(service: LiveProfileServiceProtocol) {
    self.service = service
  }

  func prepare() async {
    guard state == .idle else { return }
    state = .loading
    do {
      let identity = try await service.accountIdentity()
      email = identity.email
      name = identity.name
      managedByOIDC = identity.managedByOIDC
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func save() async {
    guard !isSaving, !managedByOIDC else { return }
    isSaving = true
    defer { isSaving = false }
    do {
      try await service.updateIdentity(
        email: email.trimmingCharacters(
          in: .whitespacesAndNewlines
        ),
        name: name.trimmingCharacters(
          in: .whitespacesAndNewlines
        ),
        currentPassword: currentPassword
      )
      currentPassword = ""
      message = "Account identity updated"
    } catch {
      errorMessage = text(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The account identity could not be updated."
  }
}
