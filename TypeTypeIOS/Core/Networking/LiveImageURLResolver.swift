import Foundation

enum LiveImageURLResolver {
  static var baseURLProvider: () -> URL? = { nil }

  static func resolve(_ reference: String?) -> URL? {
    guard var reference = reference?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ), !reference.isEmpty
    else { return nil }
    // The server sometimes emits "httpss://".
    if reference.hasPrefix("httpss://") {
      reference = "https://" + reference.dropFirst("httpss://".count)
    } else if reference.hasPrefix("//") {
      reference = "https:" + reference
    }
    return resolve(URL(string: reference))
  }

  static func resolve(_ url: URL?) -> URL? {
    guard let url else { return nil }
    if url.scheme == "http" || url.scheme == "https" {
      return LiveBilibiliImageSize.sized(url)
    }
    guard let base = baseURLProvider() else { return url }
    let baseString = base.absoluteString.hasSuffix("/")
      ? String(base.absoluteString.dropLast())
      : base.absoluteString
    let reference = url.absoluteString
    if reference.hasPrefix("/") {
      return URL(string: baseString + reference) ?? url
    }
    guard let root = URL(string: baseString + "/") else { return url }
    return URL(string: reference, relativeTo: root)?.absoluteURL ?? url
  }
}
