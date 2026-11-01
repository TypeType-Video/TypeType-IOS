import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveRecommendationRefusalsTests: XCTestCase {
  func testRefusalKeepsTheFeedbackIDForUndo() async {
    let service = RecommenderFeedbackStub(refuseResult: .success("feedback-1"))
    let refusals = LiveRecommendationRefusals(service: service)
    let video = LiveVideoItemFixture.make()

    let refuseFailure = await refusals.refuse(video)
    XCTAssertNil(refuseFailure)
    XCTAssertEqual(refusals.state(for: video), .saved(id: "feedback-1"))
    XCTAssertEqual(service.refused, [video.url])

    let undoFailure = await refusals.undo(video)
    XCTAssertNil(undoFailure)
    XCTAssertNil(refusals.state(for: video))
    XCTAssertEqual(service.withdrawn, ["feedback-1"])
  }

  func testFailedRefusalPutsTheCardBack() async {
    let service = RecommenderFeedbackStub(refuseResult: .failure(URLError(.notConnectedToInternet)))
    let refusals = LiveRecommendationRefusals(service: service)
    let video = LiveVideoItemFixture.make()

    let failure = await refusals.refuse(video)

    XCTAssertNotNil(failure)
    XCTAssertNil(refusals.state(for: video))
  }

  func testFailedUndoKeepsTheRefusal() async {
    let service = RecommenderFeedbackStub(refuseResult: .success("feedback-1"))
    service.withdrawError = URLError(.timedOut)
    let refusals = LiveRecommendationRefusals(service: service)
    let video = LiveVideoItemFixture.make()

    _ = await refusals.refuse(video)
    let failure = await refusals.undo(video)

    XCTAssertNotNil(failure)
    XCTAssertEqual(refusals.state(for: video), .saved(id: "feedback-1"))
  }

  func testPageWithRowsComesFromTheRecommender() throws {
    let standard = Data(#"{"items":[],"nextCursor":null,"hasMore":false}"#.utf8)
    let recommended = Data(
      #"{"items":[],"hasMore":false,"rows":[{"id":"r1","title":"Music","reason":"topic","videoUrls":[]}]}"#.utf8
    )

    XCTAssertFalse(try JSONDecoder().decode(HomeRecommendationsPage.self, from: standard).comesFromRecommender)
    XCTAssertTrue(try JSONDecoder().decode(HomeRecommendationsPage.self, from: recommended).comesFromRecommender)
  }

  func testHiddenVideosDropBlockedVideosAndChannelsUntilUnblocked() {
    let hidden = LiveHiddenVideos()
    let first = LiveVideoItemFixture.make()
    let second = LiveVideoItemFixture.make(id: "video-2", url: "https://www.youtube.com/watch?v=video-2")

    hidden.hide(.blockedVideos, url: first.url)
    XCTAssertEqual(hidden.visible([first, second]).map(\.id), ["video-2"])

    hidden.hide(.blockedChannels, url: second.uploaderURL)
    XCTAssertTrue(hidden.visible([first, second]).isEmpty)

    hidden.show(.blockedChannels, url: second.uploaderURL)
    hidden.show(.blockedVideos, url: first.url)
    XCTAssertEqual(hidden.visible([first, second]).count, 2)
  }
}

private final class RecommenderFeedbackStub: LiveRecommenderFeedbackServiceProtocol {
  let refuseResult: Result<String, Error>
  var withdrawError: Error?
  private(set) var refused: [String] = []
  private(set) var withdrawn: [String] = []

  init(refuseResult: Result<String, Error>) {
    self.refuseResult = refuseResult
  }

  func refuse(_ video: LiveVideoItem) async throws -> String {
    refused.append(video.url)
    return try refuseResult.get()
  }

  func withdraw(id: String) async throws {
    if let withdrawError { throw withdrawError }
    withdrawn.append(id)
  }
}
