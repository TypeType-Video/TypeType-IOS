import Foundation

/// Canonicalizes channel URLs so every comparison and request sees one form.
///
/// The server canonicalizes on subscribe (https scheme, no trailing slash,
/// no query or fragment) while stream metadata delivers raw uploader URLs.
/// Without one shared canonical form the same channel compares as different
/// identities depending on where it was opened from, and allow- or
/// block-list matching on the server can disagree with the app. The path
/// form is left untouched: `@handle` and `/channel/UC...` cannot be unified
/// without a lookup.
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
