import Foundation

enum LiveShareURLBuilder {
  static func video(
    serverURL: URL?,
    sourceURL: String
  ) -> URL? {
    guard let source = URL(string: sourceURL) else { return nil }
    guard let serverURL,
      var components = URLComponents(
        url: serverURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return source
    }

    var basePath = components.path
    if basePath.hasSuffix("/") {
      basePath.removeLast()
    }
    if basePath.hasSuffix("/api") {
      basePath.removeLast(4)
    }
    components.path = "\(basePath)/watch"
    components.queryItems = [
      URLQueryItem(name: "v", value: sourceURL),
    ]
    components.fragment = nil
    return components.url ?? source
  }
}
