import Foundation

enum ServerProbeError: LocalizedError {
  case invalidServerURL
  case unreachable
  case rejected(Int)
  case incompatible

  var errorDescription: String? {
    switch self {
    case .invalidServerURL:
      return "Server URL is invalid."
    case .unreachable:
      return "Cannot reach this TypeType instance."
    case let .rejected(status):
      return "The instance rejected the probe with HTTP \(status)."
    case .incompatible:
      return "The server did not return compatible TypeType metadata."
    }
  }
}

protocol ServerProbeServiceProtocol {
  func probe(baseURL: URL) async throws -> InstanceMetadata
}

final class ServerProbeService: ServerProbeServiceProtocol {
  private let session: URLSession
  private let decoder: JSONDecoder

  init(
    session: URLSession = .shared,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.session = session
    self.decoder = decoder
  }

  func probe(baseURL: URL) async throws -> InstanceMetadata {
    guard var components = URLComponents(
      url: baseURL,
      resolvingAgainstBaseURL: false
    ) else {
      throw ServerProbeError.invalidServerURL
    }

    let basePath = components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path = "\(basePath)/instance"
    components.query = nil
    components.fragment = nil

    guard let url = components.url else {
      throw ServerProbeError.invalidServerURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = HTTPMethod.get.rawValue
    request.timeoutInterval = 10
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    do {
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw ServerProbeError.incompatible
      }
      guard (200...299).contains(http.statusCode) else {
        throw ServerProbeError.rejected(http.statusCode)
      }
      do {
        return try decoder.decode(InstanceMetadata.self, from: data)
      } catch {
        throw ServerProbeError.incompatible
      }
    } catch let error as ServerProbeError {
      throw error
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      throw ServerProbeError.unreachable
    }
  }
}
