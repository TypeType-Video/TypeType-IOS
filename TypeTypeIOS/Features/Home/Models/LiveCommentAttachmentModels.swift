import Foundation

struct LiveCommentImage: Decodable, Equatable, Hashable {
  let url: String?
  let animated: Bool
  let unavailableText: String?

  init(url: String?, animated: Bool = false, unavailableText: String? = nil) {
    self.url = url
    self.animated = animated
    self.unavailableText = unavailableText
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    url = try values.decodeIfPresent(String.self, forKey: .url).flatMap { $0.isEmpty ? nil : $0 }
    animated = try values.decodeIfPresent(Bool.self, forKey: .animated) ?? false
    unavailableText = try values.decodeIfPresent(String.self, forKey: .unavailableText)
  }

  private enum CodingKeys: String, CodingKey {
    case url, animated, unavailableText
  }
}

struct LiveCommentVoiceReply: Decodable, Equatable, Hashable {
  let url: String
  let duration: TimeInterval
  let transcript: String
  let playable: Bool
  let unavailableText: String?

  init(url: String, duration: TimeInterval, transcript: String = "", playable: Bool = true, unavailableText: String? = nil) {
    self.url = url
    self.duration = duration
    self.transcript = transcript
    self.playable = playable
    self.unavailableText = unavailableText
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    url = try values.decodeIfPresent(String.self, forKey: .url) ?? ""
    duration = TimeInterval(try values.decodeIfPresent(Int64.self, forKey: .durationMs) ?? 0) / 1_000
    transcript = try values.decodeIfPresent(String.self, forKey: .transcript) ?? ""
    playable = try values.decodeIfPresent(Bool.self, forKey: .playable) ?? false
    unavailableText = try values.decodeIfPresent(String.self, forKey: .unavailableText)
  }

  var canPlay: Bool { playable && !url.isEmpty }

  private enum CodingKeys: String, CodingKey {
    case url, durationMs, transcript, playable, unavailableText
  }
}

struct LiveCommentSearchPage: Decodable, Equatable {
  let comments: [LiveCommentItem]
  let nextPage: String?
  let commentsDisabled: Bool

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    comments = try values.decodeIfPresent([LiveCommentItem].self, forKey: .comments) ?? []
    nextPage = try values.decodeIfPresent(String.self, forKey: .nextPage).flatMap { $0.isEmpty ? nil : $0 }
    commentsDisabled = try values.decodeIfPresent(Bool.self, forKey: .commentsDisabled) ?? false
  }

  private enum CodingKeys: String, CodingKey {
    case comments, commentsDisabled
    case nextPage = "nextpage"
  }
}
