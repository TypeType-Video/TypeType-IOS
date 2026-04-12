import Foundation

struct WatchComment: Decodable, Identifiable {
  let id: String
  let text: String
  let author: String
  let authorUrl: String
  let authorAvatarUrl: String
  let likeCount: Int64
  let textualLikeCount: String
  let publishedTime: String
  let publishedAt: Int64?
  let isHeartedByUploader: Bool
  let isPinned: Bool
  let uploaderVerified: Bool
  let replyCount: Int
  let repliesPage: String?
}

struct WatchCommentsPage: Decodable {
  let comments: [WatchComment]
  let nextPage: String?
  let commentsDisabled: Bool

  private enum CodingKeys: String, CodingKey {
    case comments
    case nextPage = "nextpage"
    case commentsDisabled
  }
}
