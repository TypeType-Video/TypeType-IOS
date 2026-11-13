import Foundation

struct LiveCommunityPost: Decodable, Equatable, Identifiable {
  let id: String
  let text: String
  let authorName: String
  let authorAvatarURL: String
  let publishedTime: String
  let publishedAt: Int64?
  let textualLikeCount: String
  let textualCommentCount: String
  let images: [String]
  let poll: Poll?
  let video: Video?
  let sharedPost: Shared?

  struct Poll: Decodable, Equatable {
    let choices: [String]
    let textualVoteCount: String

    private struct Choice: Decodable {
      let text: String?
    }

    init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      choices = (try values.decodeIfPresent([Choice].self, forKey: .choices) ?? []).compactMap(\.text)
      textualVoteCount = try values.decodeIfPresent(String.self, forKey: .textualVoteCount) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
      case choices, textualVoteCount
    }
  }

  struct Video: Decodable, Equatable {
    let url: String
    let title: String
    let thumbnailURL: String

    init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      url = try values.decode(String.self, forKey: .url)
      title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
      thumbnailURL = try values.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
      case url, title
      case thumbnailURL = "thumbnailUrl"
    }
  }

  final class Shared: Decodable, Equatable {
    let post: LiveCommunityPost

    init(from decoder: Decoder) throws {
      post = try LiveCommunityPost(from: decoder)
    }

    static func == (lhs: Shared, rhs: Shared) -> Bool { lhs.post == rhs.post }
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    text = try values.decodeIfPresent(String.self, forKey: .text) ?? ""
    authorName = try values.decodeIfPresent(String.self, forKey: .authorName) ?? ""
    authorAvatarURL = try values.decodeIfPresent(String.self, forKey: .authorAvatarURL) ?? ""
    publishedTime = try values.decodeIfPresent(String.self, forKey: .publishedTime) ?? ""
    publishedAt = try values.decodeIfPresent(Int64.self, forKey: .publishedAt)
    textualLikeCount = try values.decodeIfPresent(String.self, forKey: .textualLikeCount) ?? ""
    textualCommentCount = try values.decodeIfPresent(String.self, forKey: .textualCommentCount) ?? ""
    images = try values.decodeIfPresent([String].self, forKey: .images) ?? []
    poll = try values.decodeIfPresent(Poll.self, forKey: .poll)
    video = try values.decodeIfPresent(Video.self, forKey: .video)
    sharedPost = try values.decodeIfPresent(Shared.self, forKey: .sharedPost)
  }

  var displayText: String { LiveDescriptionTextFormatter.plainText(fromHTML: text) }

  var publishedDisplay: String {
    guard let publishedAt, publishedAt > 0 else { return publishedTime }
    let seconds = publishedAt > 10_000_000_000 ? TimeInterval(publishedAt) / 1_000 : TimeInterval(publishedAt)
    return RelativeDateTimeFormatter().localizedString(for: Date(timeIntervalSince1970: seconds), relativeTo: .now)
  }

  private enum CodingKeys: String, CodingKey {
    case id, text, authorName, publishedTime, publishedAt, textualLikeCount, textualCommentCount, images, poll, video, sharedPost
    case authorAvatarURL = "authorAvatarUrl"
  }
}

struct LiveCommunityPostsPage: Decodable, Equatable {
  let posts: [LiveCommunityPost]
  let nextPage: String?

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    posts = try values.decodeIfPresent([LiveCommunityPost].self, forKey: .posts) ?? []
    nextPage = try values.decodeIfPresent(String.self, forKey: .nextPage).flatMap { $0.isEmpty ? nil : $0 }
  }

  private enum CodingKeys: String, CodingKey {
    case posts
    case nextPage = "nextpage"
  }
}
