import Foundation

enum OIDCAuthenticationError: LocalizedError {
  case disabled
  case invalidRedirectURI

  var errorDescription: String? {
    switch self {
    case .disabled:
      return "OIDC is disabled on this TypeType instance."
    case .invalidRedirectURI:
      return "The TypeType OIDC callback URL is invalid."
    }
  }
}

@MainActor
final class OIDCAuthenticationCoordinator {
  static let callbackScheme = "typetype"

  private let oidcService: OIDCServiceProtocol
  private let authService: AuthServiceProtocol
  private let webAuthentication: any OIDCWebAuthenticating

  init(
    oidcService: OIDCServiceProtocol,
    authService: AuthServiceProtocol,
    webAuthentication: (any OIDCWebAuthenticating)? = nil
  ) {
    self.oidcService = oidcService
    self.authService = authService
    self.webAuthentication =
      webAuthentication ?? OIDCWebAuthenticationSession()
  }

  func signIn(returnTo: String? = nil) async throws -> AuthSessionResult {
    let status = try await oidcService.status()
    guard status.enabled else {
      throw OIDCAuthenticationError.disabled
    }
    let redirectURI = try Self.redirectURI()
    let authorizationURL = try await oidcService.start(
      redirectURI: redirectURI,
      returnTo: returnTo
    )
    let authorizationCode = try await webAuthentication.authorize(
      authorizationURL: authorizationURL,
      callbackScheme: Self.callbackScheme
    )
    let callback = try await oidcService.complete(
      authorizationCode: authorizationCode,
      redirectURI: redirectURI
    )
    let user = try await authService.user(
      accessToken: callback.accessToken
    )
    return AuthSessionResult(
      user: user,
      accountIdentifier: user.publicUsername,
      accessToken: callback.accessToken
    )
  }

  private static func redirectURI() throws -> URL {
    var components = URLComponents()
    components.scheme = callbackScheme
    components.host = "auth"
    components.path = "/oidc/callback"
    guard let url = components.url else {
      throw OIDCAuthenticationError.invalidRedirectURI
    }
    return url
  }
}
