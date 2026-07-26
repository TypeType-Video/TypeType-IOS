import AuthenticationServices
import Foundation
import UIKit

enum OIDCWebAuthenticationError: LocalizedError {
  case alreadyRunning
  case couldNotStart
  case invalidCallback
  case provider(String)

  var errorDescription: String? {
    switch self {
    case .alreadyRunning:
      return "An identity-provider sign-in is already running."
    case .couldNotStart:
      return "The identity-provider sign-in could not start."
    case .invalidCallback:
      return "The identity provider returned an invalid callback."
    case let .provider(message):
      return message
    }
  }
}

@MainActor
protocol OIDCWebAuthenticating: AnyObject {
  func authorize(
    authorizationURL: URL,
    callbackScheme: String
  ) async throws -> OIDCAuthorizationCode
}

@MainActor
final class OIDCWebAuthenticationSession: NSObject,
  OIDCWebAuthenticating {
  private var session: ASWebAuthenticationSession?

  func authorize(
    authorizationURL: URL,
    callbackScheme: String
  ) async throws -> OIDCAuthorizationCode {
    guard session == nil else {
      throw OIDCWebAuthenticationError.alreadyRunning
    }

    return try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: authorizationURL,
        callbackURLScheme: callbackScheme
      ) { [weak self] callbackURL, error in
        Task { @MainActor in
          self?.session = nil
          if let error {
            continuation.resume(throwing: error)
            return
          }
          do {
            let code = try Self.authorizationCode(
              from: callbackURL
            )
            continuation.resume(returning: code)
          } catch {
            continuation.resume(throwing: error)
          }
        }
      }
      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = false
      self.session = session
      guard session.start() else {
        self.session = nil
        continuation.resume(
          throwing: OIDCWebAuthenticationError.couldNotStart
        )
        return
      }
    }
  }

  private static func authorizationCode(
    from callbackURL: URL?
  ) throws -> OIDCAuthorizationCode {
    guard let callbackURL,
      let components = URLComponents(
        url: callbackURL,
        resolvingAgainstBaseURL: false
      )
    else {
      throw OIDCWebAuthenticationError.invalidCallback
    }
    let values = Dictionary(
      uniqueKeysWithValues: (components.queryItems ?? []).map {
        ($0.name, $0.value ?? "")
      }
    )
    if let providerError = values["error"], !providerError.isEmpty {
      let description = values["error_description"]
      let message = description?.isEmpty == false
        ? description ?? providerError
        : providerError
      throw OIDCWebAuthenticationError.provider(
        message
      )
    }
    guard let code = values["code"], !code.isEmpty,
      let state = values["state"], !state.isEmpty
    else {
      throw OIDCWebAuthenticationError.invalidCallback
    }
    return OIDCAuthorizationCode(code: code, state: state)
  }
}

extension OIDCWebAuthenticationSession:
  ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(
    for session: ASWebAuthenticationSession
  ) -> ASPresentationAnchor {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    for scene in scenes where scene.activationState == .foregroundActive {
      if let window = scene.windows.first(where: \.isKeyWindow) {
        return window
      }
    }
    return ASPresentationAnchor()
  }
}
