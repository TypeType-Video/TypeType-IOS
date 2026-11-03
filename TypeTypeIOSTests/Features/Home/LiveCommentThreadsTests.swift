import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveCommentThreadsTests: XCTestCase {
  func testOpenedRepliesOutliveTheRowThatAskedForThem() async {
    let service = RepliesServiceStub(pages: ["p1": Self.page(["r1", "r2"], next: "p2")])
    let threads = LiveCommentThreads(videoURL: "https://example.test/v", service: service)
    let comment = Self.comment("c1", repliesPage: "p1")

    await threads.toggle(comment)

    let thread = threads.thread(for: comment)
    XCTAssertTrue(thread.isVisible)
    XCTAssertEqual(thread.replies.map(\.id), ["r1", "r2"])
    XCTAssertEqual(thread.nextPage, "p2")
    XCTAssertFalse(threads.thread(for: Self.comment("c2", repliesPage: "x")).isVisible)
  }

  func testNextPageAppendsWithoutDuplicates() async {
    let service = RepliesServiceStub(pages: [
      "p1": Self.page(["r1", "r2"], next: "p2"),
      "p2": Self.page(["r2", "r3"], next: nil),
    ])
    let threads = LiveCommentThreads(videoURL: "https://example.test/v", service: service)
    let comment = Self.comment("c1", repliesPage: "p1")

    await threads.toggle(comment)
    await threads.loadMore(comment)

    XCTAssertEqual(threads.thread(for: comment).replies.map(\.id), ["r1", "r2", "r3"])
    XCTAssertNil(threads.thread(for: comment).nextPage)
  }

  func testHidingAndShowingAgainKeepsTheLoadedReplies() async {
    let service = RepliesServiceStub(pages: ["p1": Self.page(["r1"], next: nil)])
    let threads = LiveCommentThreads(videoURL: "https://example.test/v", service: service)
    let comment = Self.comment("c1", repliesPage: "p1")

    await threads.toggle(comment)
    await threads.toggle(comment)
    XCTAssertFalse(threads.thread(for: comment).isVisible)
    await threads.toggle(comment)

    XCTAssertTrue(threads.thread(for: comment).isVisible)
    XCTAssertEqual(service.requests, ["p1"])
  }

  func testFailureKeepsTheThreadClosedWithAMessage() async {
    let service = RepliesServiceStub(pages: [:])
    let threads = LiveCommentThreads(videoURL: "https://example.test/v", service: service)
    let comment = Self.comment("c1", repliesPage: "p1")

    await threads.toggle(comment)

    let thread = threads.thread(for: comment)
    XCTAssertFalse(thread.isVisible)
    XCTAssertFalse(thread.isLoading)
    XCTAssertNotNil(thread.errorMessage)
  }

  private static func page(_ ids: [String], next: String?) -> LiveCommentsPage {
    LiveCommentsPage(comments: ids.map { comment($0, repliesPage: nil) }, nextPage: next, commentsDisabled: false)
  }

  private static func comment(_ id: String, repliesPage: String?) -> LiveCommentItem {
    LiveCommentItem(
      id: id,
      text: id,
      author: "Someone",
      authorURL: "",
      authorAvatarURL: "",
      likeCount: 0,
      textualLikeCount: "0",
      publishedTime: "",
      publishedAt: nil,
      isHeartedByUploader: false,
      isPinned: false,
      uploaderVerified: false,
      replyCount: repliesPage == nil ? 0 : 2,
      repliesPage: repliesPage
    )
  }
}

private final class RepliesServiceStub: LiveCommentsServiceProtocol {
  let pages: [String: LiveCommentsPage]
  private(set) var requests: [String] = []

  init(pages: [String: LiveCommentsPage]) {
    self.pages = pages
  }

  func comments(url: String, nextPage: String?) async throws -> LiveCommentsPage {
    throw NetworkError.transport
  }

  func replies(url: String, repliesPage: String) async throws -> LiveCommentsPage {
    requests.append(repliesPage)
    guard let page = pages[repliesPage] else { throw NetworkError.transport }
    return page
  }
}
