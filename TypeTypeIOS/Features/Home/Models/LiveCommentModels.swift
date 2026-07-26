import Foundation

struct LiveCommentItem: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let text: String
  let author: String
  let authorURL: String
  let authorAvatarURL: String
  let likeCount: Int64
  let textualLikeCount: String
  let publishedTime: String
  let publishedAt: Int64?
  let isHeartedByUploader: Bool
  let isPinned: Bool
  let uploaderVerified: Bool
  let replyCount: Int
  let repliesPage: String?

  var authorAvatar: URL? {
    URL(string: authorAvatarURL)
  }

  private enum CodingKeys: String, CodingKey {
    case id, text, author, likeCount, textualLikeCount, publishedTime
    case authorURL = "authorUrl"
    case authorAvatarURL = "authorAvatarUrl"
    case publishedAt, isHeartedByUploader, isPinned
    case uploaderVerified, replyCount, repliesPage
  }
}

struct LiveCommentsPage: Decodable, Equatable {
  let comments: [LiveCommentItem]
  let nextPage: String?
  let commentsDisabled: Bool

  private enum CodingKeys: String, CodingKey {
    case comments
    case nextPage = "nextpage"
    case commentsDisabled
  }
}
