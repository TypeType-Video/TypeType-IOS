import Foundation

// Full-size BiliBili covers and avatars weigh several hundred kilobytes; its image service scales them when
// the path ends with these suffixes, the sizes the web client asks for.
enum LiveBilibiliImageSize {
  static let cover = "@672w_378h_1c.webp"
  static let avatar = "@240w_240h_1c.webp"

  static func sized(_ url: URL) -> URL {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let host = components.host?.lowercased(),
      host.hasSuffix("hdslb.com") || host.hasSuffix("biliimg.com")
    else { return url }
    let path = components.percentEncodedPath
    let size: String
    if path.contains("@") {
      return url
    } else if path.hasPrefix("/bfs/archive/") {
      size = cover
    } else if path.hasPrefix("/bfs/face/") {
      size = avatar
    } else {
      return url
    }
    components.scheme = "https"
    components.port = nil
    if host.hasSuffix("biliimg.com") { components.host = "i0.hdslb.com" }
    components.percentEncodedPath = path + size
    return components.url ?? url
  }
}
