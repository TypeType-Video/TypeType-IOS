import Foundation

extension LiveMediaLinkResolver {
  // Series and collections, from the share links the site uses, rewritten to the address the server reads.
  static func biliBiliCollection(_ url: URL) -> URL? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    let query = { (name: String) in components.queryItems?.first { $0.name == name }?.value }
    let segments = url.path.split(separator: "/").map(String.init)
    let mid = query("mid") ?? segments.first { $0.allSatisfy(\.isNumber) } ?? ""
    var found: (series: Bool, id: String)?
    if let business = query("business"), let id = query("business_id"), ["space_series", "space_collection"].contains(business) {
      found = (business == "space_series", id)
    } else if let sid = query("sid"), url.path.contains("seriesdetail") || url.path.contains("collectiondetail") {
      found = (url.path.contains("seriesdetail"), sid)
    } else if segments.count >= 3, segments[1] == "lists", segments[0].allSatisfy(\.isNumber), segments[2].allSatisfy(\.isNumber),
      let type = query("type")?.lowercased(), ["series", "season"].contains(type) {
      found = (type == "series", segments[2])
    }
    guard let found, !found.id.isEmpty, found.id.allSatisfy(\.isNumber), mid.allSatisfy(\.isNumber) else { return nil }
    let business = found.series ? "space_series" : "space_collection"
    return URL(string: "https://www.bilibili.com/medialist/play/\(mid)?business=\(business)&business_id=\(found.id)")
  }
}
