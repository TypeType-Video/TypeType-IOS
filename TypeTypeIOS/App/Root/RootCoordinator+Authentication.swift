import Foundation

extension RootCoordinator {
  func login(identifier: String, password: String) async throws {
    let result = try await dependencies.authService.login(
      identifier: identifier,
      password: password
    )
    completeAuthentication(result)
  }

  func register(
    name: String,
    email: String,
    password: String
  ) async throws {
    let result = try await dependencies.authService.register(
      name: name,
      email: email,
      password: password
    )
    completeAuthentication(result)
  }

  func continueAsGuest() async throws {
    completeAuthentication(
      try await dependencies.authService.guestLogin()
    )
  }

  func continueWithOIDC() async throws {
    let coordinator = OIDCAuthenticationCoordinator(
      oidcService: dependencies.oidcService,
      authService: dependencies.authService
    )
    completeAuthentication(try await coordinator.signIn())
  }
}
