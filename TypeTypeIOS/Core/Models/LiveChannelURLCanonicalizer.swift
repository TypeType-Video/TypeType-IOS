import Foundation

/// The server's subscribe form (https, no trailing slash, no query or fragment), so a channel matches
/// itself wherever it was opened from. `@handle` and `/channel/UC...` stay apart: unifying needs a lookup.
enum LiveChannelURLCanonicalizer {
  static func canonicalize(_ channelURL: String) -> String {
    guard channelURL.hasPrefix("http://") || channelURL.hasPrefix("https://"),
      var components = URLComponents(string: channelURL)
    else {
      return channelURL
    }
    if components.scheme?.lowercased() == "http" {
      components.scheme = "https"
    }
    components.query = nil
    components.fragment = nil
    var path = components.path
    while path.hasSuffix("/") {
      path = String(path.dropLast())
    }
    components.path = path
    return components.url?.absoluteString ?? channelURL
  }

  /// Identity for comparisons: the canonical form, case-folded, because
  /// hosts and handles compare equal regardless of casing.
  static func identity(_ channelURL: String) -> String {
    canonicalize(channelURL).lowercased()
  }
}
