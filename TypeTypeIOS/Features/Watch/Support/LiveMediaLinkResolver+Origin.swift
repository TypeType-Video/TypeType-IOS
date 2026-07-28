import Foundation

extension LiveMediaLinkResolver {
  static func sameOrigin(_ lhs: URL, _ rhs: URL) -> Bool {
    guard let lhsScheme = lhs.scheme?.lowercased(),
      let rhsScheme = rhs.scheme?.lowercased(),
      lhsScheme == rhsScheme,
      lhs.host?.lowercased() == rhs.host?.lowercased()
    else {
      return false
    }
    return effectivePort(lhs) == effectivePort(rhs)
  }

  private static func effectivePort(_ url: URL) -> Int? {
    if let port = url.port { return port }
    switch url.scheme?.lowercased() {
    case "http": return 80
    case "https": return 443
    default: return nil
    }
  }
}
