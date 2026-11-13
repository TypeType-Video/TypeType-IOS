import Foundation

enum NetworkError: Error {
  case missingServerURL
  case invalidURL
  case missingAccessToken
  case invalidResponse
  case statusCode(Int, String?, code: String? = nil)
  case decoding
  case transport
}

extension NetworkError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .missingServerURL:
      return String(localized: "No instance is selected.")
    case .invalidURL:
      return String(localized: "This address is not valid.")
    case .missingAccessToken:
      return LiveUserError(self).message
    case .invalidResponse, .decoding:
      return String(localized: "The instance sent an answer this app does not understand.")
    case let .statusCode(status, message, _):
      if let known = LiveUserError(self).message { return known }
      if let message, !message.isEmpty { return message }
      return String(localized: "The request failed (\(status)).")
    case .transport:
      return LiveUserError(self).message
    }
  }
}

extension NetworkError: CustomStringConvertible {
  var description: String {
    switch self {
    case let .statusCode(status, message, code):
      return "HTTP \(status) code=\(code ?? "-") \(message ?? "")"
    case .missingServerURL: return "missingServerURL"
    case .invalidURL: return "invalidURL"
    case .missingAccessToken: return "missingAccessToken"
    case .invalidResponse: return "invalidResponse"
    case .decoding: return "decoding"
    case .transport: return "transport"
    }
  }
}
