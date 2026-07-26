import Foundation

struct OIDCStatus: Decodable, Equatable {
  let enabled: Bool
  let providerName: String?
  let localLoginEnabled: Bool
  let autoRedirect: Bool
}

struct OIDCStartResponse: Decodable, Equatable {
  let authorizationURL: URL

  private enum CodingKeys: String, CodingKey {
    case authorizationURL = "authorizationUrl"
  }
}

struct OIDCCallbackPayload: Encodable {
  let code: String
  let state: String
  let redirectUri: String
}

struct OIDCCallbackResponse: Decodable, Equatable {
  let accessToken: String
  let returnTo: String
}

struct OIDCAuthorizationCode: Equatable {
  let code: String
  let state: String
}
