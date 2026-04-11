import Foundation

enum NetworkError: Error {
  case missingServerURL
  case invalidURL
  case missingAccessToken
  case invalidResponse
  case statusCode(Int, String?)
  case decoding
  case transport
}

extension NetworkError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .missingServerURL:
      return "Server URL is not configured."
    case .invalidURL:
      return "Invalid request URL."
    case .missingAccessToken:
      return "Session token is missing."
    case .invalidResponse:
      return "Invalid server response."
    case let .statusCode(code, message):
      if let message, !message.isEmpty {
        return "Request failed (\(code)): \(message)"
      }
      return "Request failed with status \(code)."
    case .decoding:
      return "Failed to decode server payload."
    case .transport:
      return "Network transport failed."
    }
  }
}
