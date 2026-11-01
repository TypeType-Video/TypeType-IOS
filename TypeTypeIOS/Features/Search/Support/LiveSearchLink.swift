import Foundation

enum LiveSearchLink {
  static func destination(for input: String, serverURL: URL?) -> LiveMediaLinkDestination? {
    url(from: input).flatMap { LiveMediaLinkResolver.destination(for: $0, serverURL: serverURL) }
  }

  // Bare video IDs stay searches: any 11-letter word would otherwise open a video.
  static func url(from input: String) -> URL? {
    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
      return nil
    }
    if let url = URL(string: value), let scheme = url.scheme?.lowercased(),
      ["http", "https", "typetype"].contains(scheme) {
      return url
    }
    guard let host = value.split(separator: "/", maxSplits: 1).first,
      host.contains("."), !host.contains(":")
    else {
      return nil
    }
    return URL(string: "https://\(value)")
  }
}
