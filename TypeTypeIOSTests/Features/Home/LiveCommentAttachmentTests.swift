import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveCommentAttachmentTests: XCTestCase {
  func testReadsImagesAndVoiceReplies() throws {
    let json = """
      {"comments":[{"id":"a","text":"hi","author":"A","authorUrl":"","authorAvatarUrl":"","likeCount":0,
      "textualLikeCount":"0","publishedTime":"","isHeartedByUploader":false,"isPinned":false,"uploaderVerified":false,
      "replyCount":0,"image":{"url":"https://yt3.ggpht.com/x.gif","animated":true},
      "voiceReply":{"url":"https://www.youtube.com/watch?v=v","durationMs":4500,"transcript":"thanks","playable":true}}],
      "nextpage":null,"commentsDisabled":false}
      """
    let comment = try XCTUnwrap(JSONDecoder().decode(LiveCommentsPage.self, from: Data(json.utf8)).comments.first)

    XCTAssertEqual(comment.image, LiveCommentImage(url: "https://yt3.ggpht.com/x.gif", animated: true))
    XCTAssertEqual(comment.voiceReply?.duration, 4.5)
    XCTAssertEqual(comment.voiceReply?.transcript, "thanks")
    XCTAssertEqual(comment.voiceReply?.canPlay, true)
  }

  func testCommentsWithoutAttachmentsStillDecode() throws {
    let json = #"{"id":"a","text":"hi","author":"A","authorUrl":"","authorAvatarUrl":"","likeCount":0,"textualLikeCount":"0","publishedTime":"","isHeartedByUploader":false,"isPinned":false,"uploaderVerified":false,"replyCount":0}"#
    let comment = try JSONDecoder().decode(LiveCommentItem.self, from: Data(json.utf8))
    XCTAssertNil(comment.image)
    XCTAssertNil(comment.voiceReply)
  }

  func testANewSearchReplacesTheResultsAndPagesWithItsCursor() async {
    let service = SearchingCommentsService()
    let model = LiveCommentSearchViewModel(videoURL: "video", service: service)
    model.query = " first "

    await model.search()
    XCTAssertEqual(model.results.map(\.id), ["first-1"])
    await model.loadMore()
    XCTAssertEqual(model.results.map(\.id), ["first-1", "first-2"])
    XCTAssertFalse(model.canLoadMore)

    model.query = "none"
    await model.search()
    XCTAssertEqual(model.state, .empty)
    XCTAssertEqual(service.calls, ["first -", "first next", "none -"])
    model.clear()
    XCTAssertFalse(model.isActive)
  }
}

private final class SearchingCommentsService: LiveCommentsServiceProtocol {
  var calls: [String] = []

  func comments(url: String, nextPage: String?) async throws -> LiveCommentsPage { throw NetworkError.transport }

  func replies(url: String, repliesPage: String) async throws -> LiveCommentsPage { throw NetworkError.transport }

  func search(url: String, query: String, cursor: String?) async throws -> LiveCommentSearchPage {
    calls.append("\(query) \(cursor ?? "-")")
    let ids = query == "none" ? [] : [cursor == nil ? "\(query)-1" : "\(query)-2"]
    let comments = ids.map { #"{"id":"\#($0)","text":"t","author":"A","authorUrl":"","authorAvatarUrl":"","likeCount":0,"textualLikeCount":"0","publishedTime":"","isHeartedByUploader":false,"isPinned":false,"uploaderVerified":false,"replyCount":0}"# }
    let next = cursor == nil && !ids.isEmpty ? #""next""# : "null"
    let json = #"{"comments":[\#(comments.joined(separator: ","))],"nextpage":\#(next)}"#
    return try JSONDecoder().decode(LiveCommentSearchPage.self, from: Data(json.utf8))
  }
}
