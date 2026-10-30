import Foundation

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

  static func identity(_ channelURL: String) -> String {
    canonicalize(channelURL).lowercased()
  }
}
