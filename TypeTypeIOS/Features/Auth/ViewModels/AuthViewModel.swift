import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
  enum Mode: String, CaseIterable, Identifiable {
    case signIn
    case register

    var id: String { rawValue }
  }

  @Published var mode: Mode = .signIn
  @Published var name: String = ""
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  func submit(using coordinator: RootCoordinator) async {
    isLoading = true
    errorMessage = nil
    do {
      let result: AuthSessionResult
      switch mode {
      case .signIn:
        result = try await coordinator.dependencies.authService.login(
          email: email,
          password: password
        )
      case .register:
        result = try await coordinator.dependencies.authService.register(
          name: name,
          email: email,
          password: password
        )
      }
      coordinator.completeAuthentication(result)
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Authentication failed."
      isLoading = false
    } catch {
      errorMessage = "Authentication failed."
      isLoading = false
    }
  }
}
