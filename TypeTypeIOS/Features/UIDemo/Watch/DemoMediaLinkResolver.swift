import Foundation

enum DemoMediaLinkResolver {
  static func internalVideo(for url: URL) -> DemoVideo? {
    guard let host = url.host?.lowercased() else { return nil }
    let service: DemoSearchService

    if matches(host, domains: ["youtube.com", "youtu.be"]) {
      service = .youtube
    } else if matches(host, domains: ["nicovideo.jp", "nico.ms"]) {
      service = .nicoNico
    } else if matches(host, domains: ["bilibili.com", "b23.tv"]) {
      service = .biliBili
    } else {
      return nil
    }

    return DemoSearchCatalog.videos.first {
      DemoSearchCatalog.service(for: $0.id) == service
    }
  }

  private static func matches(_ host: String, domains: [String]) -> Bool {
    domains.contains { host == $0 || host.hasSuffix(".\($0)") }
  }
}

enum DemoWatchLinkCatalog {
  static let youtube = makeURL(
    host: "www.youtube.com",
    path: "/watch",
    queryItems: [URLQueryItem(name: "v", value: "YE7VzlLtp-4")]
  )
  static let nicoNico = makeURL(
    host: "www.nicovideo.jp",
    path: "/watch/sm9"
  )
  static let biliBili = makeURL(
    host: "www.bilibili.com",
    path: "/video/BV1xx411c7mD"
  )

  private static func makeURL(
    host: String,
    path: String,
    queryItems: [URLQueryItem] = []
  ) -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.path = path
    components.queryItems = queryItems
    return components.url ?? URL(fileURLWithPath: "/")
  }
}
