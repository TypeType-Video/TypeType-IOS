import Combine
import Foundation

@MainActor
final class LiveAuthViewModel: ObservableObject {
  @Published var mode = AuthMode.signIn
  @Published var name = ""
  @Published var identifier = ""
  @Published var password = ""
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published private(set) var registerStatus: RegisterStatus?
  @Published private(set) var oidcStatus: OIDCStatus?

  private var didLoad = false
  private var didAutoRedirect = false

  var canSubmit: Bool {
    let hasCredentials =
      !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !password.isEmpty
    if mode == .signIn {
      return hasCredentials && localLoginEnabled && !isLoading
    }
    return hasCredentials
      && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && identifier.contains("@")
      && password.count >= 8
      && registrationAllowed
      && localLoginEnabled
      && !isLoading
  }

  var localLoginEnabled: Bool {
    registerStatus?.localLoginEnabled
      ?? oidcStatus?.localLoginEnabled
      ?? true
  }

  var registrationAllowed: Bool {
    guard let registerStatus else { return false }
    return registerStatus.allowRegistration
      || registerStatus.bootstrapAvailable
  }

  var oidcEnabled: Bool {
    oidcStatus?.enabled == true
  }

  var oidcProviderName: String {
    oidcStatus?.providerName?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ).nilIfEmpty ?? "OpenID"
  }

  func load(using coordinator: RootCoordinator) async {
    guard !didLoad else { return }
    didLoad = true
    async let register = coordinator.dependencies.authService
      .registrationStatus()
    async let oidc = coordinator.dependencies.oidcService.status()
    registerStatus = try? await register
    oidcStatus = try? await oidc
    if registerStatus == nil, let instance = coordinator.instance {
      registerStatus = RegisterStatus(
        allowRegistration: instance.registrationAllowed,
        bootstrapAvailable: false,
        localLoginEnabled: instance.localLoginEnabled
      )
    }
    if oidcStatus == nil, let instance = coordinator.instance {
      oidcStatus = OIDCStatus(
        enabled: instance.oidcEnabled,
        providerName: instance.oidcProviderName,
        localLoginEnabled: instance.localLoginEnabled,
        autoRedirect: instance.oidcAutoRedirect
      )
    }

    guard oidcStatus?.autoRedirect == true, !didAutoRedirect else {
      return
    }
    didAutoRedirect = true
    await continueWithOIDC(using: coordinator)
  }

  func submit(using coordinator: RootCoordinator) async {
    guard canSubmit else { return }
    await perform {
      switch mode {
      case .signIn:
        try await coordinator.login(
          identifier: identifier.trimmingCharacters(
            in: .whitespacesAndNewlines
          ),
          password: password
        )
      case .register:
        try await coordinator.register(
          name: name.trimmingCharacters(in: .whitespacesAndNewlines),
          email: identifier.trimmingCharacters(
            in: .whitespacesAndNewlines
          ),
          password: password
        )
      }
    }
  }

  func continueAsGuest(using coordinator: RootCoordinator) async {
    await perform {
      try await coordinator.continueAsGuest()
    }
  }

  func continueWithOIDC(using coordinator: RootCoordinator) async {
    guard oidcEnabled else { return }
    await perform {
      try await coordinator.continueWithOIDC()
    }
  }

  func clearError() {
    errorMessage = nil
  }

  private func perform(_ action: () async throws -> Void) async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      try await action()
    } catch is CancellationError {
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
