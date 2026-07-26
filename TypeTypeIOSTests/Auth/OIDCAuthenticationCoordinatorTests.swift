import Foundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class OIDCAuthenticationCoordinatorTests: XCTestCase {
  func testCompletesNativeAuthorizationCodeFlow() async throws {
    let oidc = OIDCFlowServiceStub(enabled: true)
    let auth = OIDCAuthServiceStub()
    let browser = OIDCBrowserStub()
    let coordinator = OIDCAuthenticationCoordinator(
      oidcService: oidc,
      authService: auth,
      webAuthentication: browser
    )

    let result = try await coordinator.signIn(returnTo: "/profile")

    XCTAssertEqual(browser.callbackScheme, "typetype")
    XCTAssertEqual(
      browser.authorizationURL?.absoluteString,
      "https://identity.test/authorize"
    )
    XCTAssertEqual(
      oidc.redirectURI?.absoluteString,
      "typetype://auth/oidc/callback"
    )
    XCTAssertEqual(oidc.returnTo, "/profile")
    XCTAssertEqual(oidc.code, "native-code")
    XCTAssertEqual(oidc.state, "native-state")
    XCTAssertEqual(result.accessToken, "oidc-token")
    XCTAssertEqual(result.user.id, "oidc-user")
  }

  func testRejectsDisabledOIDCBeforeOpeningBrowser() async {
    let browser = OIDCBrowserStub()
    let coordinator = OIDCAuthenticationCoordinator(
      oidcService: OIDCFlowServiceStub(enabled: false),
      authService: OIDCAuthServiceStub(),
      webAuthentication: browser
    )

    do {
      _ = try await coordinator.signIn()
      XCTFail("Disabled OIDC should fail.")
    } catch OIDCAuthenticationError.disabled {
      XCTAssertNil(browser.authorizationURL)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}

private final class OIDCFlowServiceStub: OIDCServiceProtocol {
  let enabled: Bool
  var redirectURI: URL?
  var returnTo: String?
  var code: String?
  var state: String?

  init(enabled: Bool) {
    self.enabled = enabled
  }

  func status() async throws -> OIDCStatus {
    OIDCStatus(
      enabled: enabled,
      providerName: "Identity",
      localLoginEnabled: true,
      autoRedirect: false
    )
  }

  func start(
    redirectURI: URL,
    returnTo: String?
  ) async throws -> URL {
    self.redirectURI = redirectURI
    self.returnTo = returnTo
    guard let url = URL(string: "https://identity.test/authorize") else {
      throw OIDCFlowTestError.invalidURL
    }
    return url
  }

  func complete(
    authorizationCode: OIDCAuthorizationCode,
    redirectURI: URL
  ) async throws -> OIDCCallbackResponse {
    code = authorizationCode.code
    state = authorizationCode.state
    self.redirectURI = redirectURI
    return OIDCCallbackResponse(
      accessToken: "oidc-token",
      returnTo: "/profile"
    )
  }
}

@MainActor
private final class OIDCBrowserStub: OIDCWebAuthenticating {
  var authorizationURL: URL?
  var callbackScheme: String?

  func authorize(
    authorizationURL: URL,
    callbackScheme: String
  ) async throws -> OIDCAuthorizationCode {
    self.authorizationURL = authorizationURL
    self.callbackScheme = callbackScheme
    return OIDCAuthorizationCode(
      code: "native-code",
      state: "native-state"
    )
  }
}

private final class OIDCAuthServiceStub: AuthServiceProtocol {
  func registrationStatus() async throws -> RegisterStatus {
    throw OIDCFlowTestError.unexpectedCall
  }

  func login(
    identifier: String,
    password: String
  ) async throws -> AuthSessionResult {
    throw OIDCFlowTestError.unexpectedCall
  }

  func register(
    name: String,
    email: String,
    password: String
  ) async throws -> AuthSessionResult {
    throw OIDCFlowTestError.unexpectedCall
  }

  func guestLogin() async throws -> AuthSessionResult {
    throw OIDCFlowTestError.unexpectedCall
  }

  func refresh() async throws -> String {
    throw OIDCFlowTestError.unexpectedCall
  }

  func restoreSession(
    snapshot: SessionSnapshot,
    accessToken: String
  ) async throws -> AuthSessionResult {
    throw OIDCFlowTestError.unexpectedCall
  }

  func user(accessToken: String) async throws -> AuthUser {
    XCTAssertEqual(accessToken, "oidc-token")
    return AuthUser(
      id: "oidc-user",
      role: .user,
      publicUsername: "oidc"
    )
  }

  func logout() async throws {
    throw OIDCFlowTestError.unexpectedCall
  }
}

private enum OIDCFlowTestError: Error {
  case invalidURL
  case unexpectedCall
}
