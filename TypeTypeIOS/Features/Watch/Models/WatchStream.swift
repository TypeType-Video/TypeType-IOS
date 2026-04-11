import Foundation

struct WatchStream: Decodable {
  let title: String
  let uploaderName: String
  let uploaderUrl: String
  let uploaderAvatarUrl: String
  let thumbnailUrl: String
  let description: String
  let duration: Int64
  let viewCount: Int64
  let uploadDate: String
  let requiresMembership: Bool
  let streamType: String
  let isShortFormContent: Bool
}
