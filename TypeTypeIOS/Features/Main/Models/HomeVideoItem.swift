import Foundation

struct HomeVideoItem: Decodable, Hashable, Identifiable {
  let id: String
  let title: String
  let url: String
  let thumbnailUrl: String
  let uploaderName: String
  let uploaderUrl: String
  let uploaderAvatarUrl: String
  let duration: Int64
  let viewCount: Int64
  let uploadDate: String
  let streamType: String
  let isShortFormContent: Bool
  let uploaderVerified: Bool
  let shortDescription: String?
}
