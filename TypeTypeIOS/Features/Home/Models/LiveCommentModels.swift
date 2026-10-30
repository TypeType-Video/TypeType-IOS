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

  var publishedDisplay: String {
    if let publishedAt, publishedAt > 0 {
      let seconds = publishedAt > 10_000_000_000
        ? TimeInterval(publishedAt) / 1_000
        : TimeInterval(publishedAt)
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .full
      return formatter.localizedString(
        for: Date(timeIntervalSince1970: seconds),
        relativeTo: .now
      )
    }
    return publishedTime
  }

  var displayText: String {
    Self.readable(text)
  }

  private static func readable(_ raw: String) -> String {
    var value = raw
    for breakTag in ["<br/>", "<br />", "<br>", "<BR>"] {
      value = value.replacingOccurrences(of: breakTag, with: "\n")
    }
    value = value.replacingOccurrences(
      of: "<[^>]+>",
      with: "",
      options: .regularExpression
    )
    let entities: [(String, String)] = [
      ("&nbsp;", " "),
      ("&quot;", "\""),
      ("&#39;", "'"),
      ("&apos;", "'"),
      ("&lt;", "<"),
      ("&gt;", ">"),
      ("&amp;", "&"),
    ]
    for (entity, replacement) in entities {
      value = value.replacingOccurrences(of: entity, with: replacement)
    }
    return value
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
