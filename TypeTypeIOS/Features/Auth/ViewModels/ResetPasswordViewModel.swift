import Foundation

@MainActor
final class ResetPasswordViewModel: ObservableObject {
  @Published var token: String = ""
  @Published var newPassword: String = ""
  @Published private(set) var isSubmitting: Bool = false
  @Published var errorMessage: String?
  @Published var infoMessage: String?

  private let service: ResetPasswordServiceProtocol

  init(service: ResetPasswordServiceProtocol) {
    self.service = service
  }

  func submit() async {
    guard !isSubmitting else { return }
    isSubmitting = true
    errorMessage = nil
    infoMessage = nil

    do {
      try await service.reset(token: token, newPassword: newPassword)
      infoMessage = "Password updated"
      token = ""
      newPassword = ""
      isSubmitting = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Invalid or expired reset token."
      isSubmitting = false
    } catch {
      errorMessage = "Invalid or expired reset token."
      isSubmitting = false
    }
  }
}
