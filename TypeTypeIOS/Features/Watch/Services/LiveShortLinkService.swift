import Foundation

protocol LiveShortLinkServiceProtocol {
  func expand(code: String) async throws -> URL
}

// b23.tv links can lead to a video, a channel or a series: the server follows the redirect before the app routes it.
struct LiveShortLinkService: LiveShortLinkServiceProtocol {
  let apiClient: APIClient

  static func code(of url: URL) -> String? {
    guard url.host?.lowercased() == "b23.tv" else { return nil }
    let code = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard (4...16).contains(code.count), code.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else { return nil }
    return code
  }

  func expand(code: String) async throws -> URL {
    let answer = try await apiClient.request(APIEndpoint(path: "/links/b23/\(code)", method: .get), as: LiveShortLinkAnswer.self)
    guard let url = URL(string: answer.url) else { throw NetworkError.decoding }
    return url
  }
}

private struct LiveShortLinkAnswer: Decodable {
  let url: String
}

extension LiveShortLinkServiceProtocol {
  func resolve(_ url: URL) async -> URL {
    guard let code = LiveShortLinkService.code(of: url) else { return url }
    return (try? await expand(code: code)) ?? url
  }
}
