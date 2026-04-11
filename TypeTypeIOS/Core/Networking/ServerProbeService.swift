import Foundation

enum ServerProbeError: LocalizedError {
  case invalidServerURL
  case unreachable
  case invalidResponse

  var errorDescription: String? {
    switch self {
    case .invalidServerURL:
      return "Server URL is invalid."
    case .unreachable:
      return "Cannot reach this server."
    case .invalidResponse:
      return "Server responded with an unexpected payload."
    }
  }
}

protocol ServerProbeServiceProtocol {
  func probe(baseURL: URL) async throws
}

final class ServerProbeService: ServerProbeServiceProtocol {
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func probe(baseURL: URL) async throws {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      throw ServerProbeError.invalidServerURL
    }

    let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
    components.path = "\(basePath)/trending"
    components.queryItems = [URLQueryItem(name: "service", value: "0")]

    guard let url = components.url else { throw ServerProbeError.invalidServerURL }
    var request = URLRequest(url: url)
    request.httpMethod = HTTPMethod.get.rawValue
    request.timeoutInterval = 8

    do {
      let (_, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw ServerProbeError.invalidResponse }
      guard (200...299).contains(http.statusCode) else { throw ServerProbeError.unreachable }
    } catch let error as ServerProbeError {
      throw error
    } catch {
      throw ServerProbeError.unreachable
    }
  }
}
