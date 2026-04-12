import Foundation

struct WatchComment: Decodable, Identifiable {
  let id: String
  let text: String
  let author: String
  let authorUrl: String
  let authorAvatarUrl: String
  let likeCount: Int64
  let publishedTime: String
  let isPinned: Bool
  let uploaderVerified: Bool
}

struct WatchCommentsPage: Decodable {
  let comments: [WatchComment]
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case comments
    case nextPage = "nextpage"
  }
}
