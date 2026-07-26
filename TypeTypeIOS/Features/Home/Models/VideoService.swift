import Foundation

struct VideoService: Identifiable, Hashable {
  let id: Int
  let name: String
  let assetName: String?
  let systemImage: String

  static func supported(_ serviceIDs: [Int]) -> [VideoService] {
    let officialServiceIDs: Set<Int> = [0, 5, 6]
    let unique = Array(
      Set(serviceIDs).intersection(officialServiceIDs)
    ).sorted()
    return unique.map(service)
  }

  static func service(for id: Int) -> VideoService {
    switch id {
    case 0:
      return VideoService(
        id: id,
        name: "YouTube",
        assetName: "ServiceYouTube",
        systemImage: "play.rectangle.fill"
      )
    case 5:
      return VideoService(
        id: id,
        name: "BiliBili",
        assetName: "ServiceBiliBili",
        systemImage: "play.tv.fill"
      )
    case 6:
      return VideoService(
        id: id,
        name: "NicoNico",
        assetName: "ServiceNicoNico",
        systemImage: "tv.fill"
      )
    default:
      return VideoService(
        id: id,
        name: "Service \(id)",
        assetName: nil,
        systemImage: "play.rectangle"
      )
    }
  }
}
