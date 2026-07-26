import Foundation

enum LiveChannelRequestURLBuilder {
  static func isYouTube(_ channelURL: String) -> Bool {
    guard let host = URLComponents(string: channelURL)?
      .host?.lowercased()
    else {
      return false
    }
    return host == "youtube.com" || host.hasSuffix(".youtube.com")
  }

  static func build(
    channelURL: String,
    query: String,
    tab: LiveChannelTab
  ) -> String {
    let term = query.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard tab == .live || !term.isEmpty else {
      return channelURL
    }
    guard var components = URLComponents(string: channelURL),
      isYouTube(channelURL)
    else {
      return channelURL
    }
    components.path = components.path
      .replacingOccurrences(
        of: #"/+$"#,
        with: "",
        options: .regularExpression
      )
      + (tab == .live ? "/streams" : "/search")
    components.queryItems = tab == .live
      ? nil
      : [URLQueryItem(name: "query", value: term)]
    components.fragment = nil
    return components.url?.absoluteString ?? channelURL
  }
}
