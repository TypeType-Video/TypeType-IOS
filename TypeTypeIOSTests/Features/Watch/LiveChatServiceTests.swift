import XCTest
@testable import TypeTypeIOS

final class LiveChatServiceTests: XCTestCase {
  private static func message(_ id: String) -> String {
    "event: message\ndata: {\"id\":\"\(id)\",\"text\":\"text \(id)\",\"receivedAtMs\":1}\n\n"
  }

  private func chatMessage(_ id: String) -> LiveChatEvent {
    .message(LiveChatMessage(id: id, author: "", text: "text \(id)", moderator: false))
  }

  private func run(_ transport: ScriptedTransport) async -> (events: [LiveChatEvent], pauses: [Duration]) {
    let pauses = PauseLog()
    let service = LiveChatService(transport: transport, pause: { await pauses.add($0) })
    var events: [LiveChatEvent] = []
    for await event in service.events(videoURL: "https://www.youtube.com/watch?v=live") { events.append(event) }
    return (events, await pauses.all)
  }

  func testDeliversMessagesUntilTheLiveEnds() async {
    let transport = ScriptedTransport([.stream(Self.message("a") + Self.message("b") + "event: ended\ndata: {}\n\n")])
    let result = await run(transport)
    XCTAssertEqual(result.events, [.connected, chatMessage("a"), chatMessage("b"), .ended])
    XCTAssertEqual(transport.opened, 1)
    XCTAssertTrue(result.pauses.isEmpty)
  }

  func testAStreamThatClosesIsOpenedAgainAfterOneSecond() async {
    let transport = ScriptedTransport([
      .stream(Self.message("a")),
      .stream(Self.message("b") + "event: ended\ndata: {}\n\n"),
    ])
    let result = await run(transport)
    XCTAssertEqual(result.events, [.connected, chatMessage("a"), .connected, chatMessage("b"), .ended])
    XCTAssertEqual(result.pauses, [.seconds(1)])
  }

  func testTheBackoffGrowsWhileNothingArrives() async {
    let down = LiveChatRefused(status: 503, retryAfter: nil)
    let transport = ScriptedTransport([.refuse(down), .refuse(down), .refuse(down), .stream("event: ended\ndata: {}\n\n")])
    let result = await run(transport)
    XCTAssertEqual(result.pauses, [.seconds(1), .seconds(2), .seconds(4)])
    XCTAssertEqual(result.events.last, .ended)
  }

  func testAMessageStartsTheBackoffOver() async {
    let drop = ScriptedTransport.Step.drop(Self.message("a"))
    let transport = ScriptedTransport([drop, drop, drop, .stream("event: ended\ndata: {}\n\n")])
    let result = await run(transport)
    XCTAssertEqual(result.pauses, [.seconds(1), .seconds(1), .seconds(1)])
  }

  func testItGivesUpAfterSixFailuresInARow() async {
    let transport = ScriptedTransport([])
    let result = await run(transport)
    XCTAssertEqual(result.events, [.unavailable])
    XCTAssertEqual(result.pauses, LiveChatRetry.backoff)
    XCTAssertEqual(transport.opened, 7)
  }

  func testAVideoWithoutChatStopsAtOnce() async {
    let transport = ScriptedTransport([.refuse(LiveChatRefused(status: 422, retryAfter: nil))])
    let result = await run(transport)
    XCTAssertEqual(result.events, [.unavailable])
    XCTAssertTrue(result.pauses.isEmpty)
    XCTAssertEqual(transport.opened, 1)
  }

  func testARefusalThatWaitingCannotChangeStops() async {
    for status in [400, 403, 404] {
      let transport = ScriptedTransport([.refuse(LiveChatRefused(status: status, retryAfter: nil))])
      let result = await run(transport)
      XCTAssertEqual(result.events, [.unavailable], "status \(status)")
    }
  }

  func testAnExpiredTokenIsTriedAgain() async {
    let transport = ScriptedTransport([
      .refuse(LiveChatRefused(status: 401, retryAfter: nil)),
      .stream("event: ended\ndata: {}\n\n"),
    ])
    let result = await run(transport)
    XCTAssertEqual(result.pauses, [.seconds(1)])
    XCTAssertEqual(result.events.last, .ended)
  }

  func testACapacityRefusalWaitsForRetryAfter() async {
    let transport = ScriptedTransport([
      .refuse(LiveChatRefused(status: 429, retryAfter: 5)),
      .refuse(LiveChatRefused(status: 429, retryAfter: 600)),
      .stream("event: ended\ndata: {}\n\n"),
    ])
    let result = await run(transport)
    XCTAssertEqual(result.pauses, [.seconds(5), .seconds(60)])
  }

  func testAnErrorEventInsideTheStreamReconnects() async {
    let transport = ScriptedTransport([
      .stream("event: error\ndata: {\"error\":\"Live chat retrieval failed\"}\n\n"),
      .stream("event: ended\ndata: {}\n\n"),
    ])
    let result = await run(transport)
    XCTAssertEqual(result.events, [.connected, .connected, .ended])
    XCTAssertEqual(result.pauses, [.seconds(1)])
  }

  func testAStreamCutByTheNetworkReconnects() async {
    let transport = ScriptedTransport([
      .dropWithError(Self.message("a")),
      .stream("event: ended\ndata: {}\n\n"),
    ])
    let result = await run(transport)
    XCTAssertEqual(result.events, [.connected, chatMessage("a"), .connected, .ended])
  }

  // Closing the panel must close the connection: the server only stops its session when the client leaves.
  func testStoppingTheConsumerClosesTheConnection() async throws {
    let transport = ScriptedTransport([.hang])
    let service = LiveChatService(transport: transport, pause: { _ in })
    var iterator: AsyncStream<LiveChatEvent>? = service.events(videoURL: "https://www.youtube.com/watch?v=live")
    var seen: LiveChatEvent?
    for await event in iterator! {
      seen = event
      break
    }
    iterator = nil
    XCTAssertEqual(seen, .connected)
    for _ in 0..<100 where !transport.closed { try await Task.sleep(for: .milliseconds(20)) }
    XCTAssertTrue(transport.closed)
  }

  func testTheDecisionTable() {
    XCTAssertEqual(LiveChatRetry.decision(afterFailure: 1, error: URLError(.timedOut)), .retry(after: .seconds(1)))
    XCTAssertEqual(LiveChatRetry.decision(afterFailure: 6, error: URLError(.timedOut)), .retry(after: .seconds(30)))
    XCTAssertEqual(LiveChatRetry.decision(afterFailure: 7, error: URLError(.timedOut)), .giveUp)
    XCTAssertEqual(LiveChatRetry.decision(afterFailure: 1, error: LiveChatRefused(status: 502, retryAfter: nil)), .retry(after: .seconds(1)))
  }
}

private actor PauseLog {
  private(set) var all: [Duration] = []
  func add(_ duration: Duration) { all.append(duration) }
}

private final class ScriptedTransport: LiveChatTransport, @unchecked Sendable {
  enum Step {
    case stream(String)
    case drop(String)
    case dropWithError(String)
    case refuse(LiveChatRefused)
    case hang
  }

  private let lock = NSLock()
  private var steps: [Step]
  private var openedCount = 0
  private var closedFlag = false

  init(_ steps: [Step]) { self.steps = steps }

  var opened: Int { lock.withLock { openedCount } }
  var closed: Bool { lock.withLock { closedFlag } }

  func open(videoURL: String) async throws -> AsyncThrowingStream<UInt8, Error> {
    let step: Step = lock.withLock {
      openedCount += 1
      return steps.isEmpty ? .refuse(LiveChatRefused(status: 500, retryAfter: nil)) : steps.removeFirst()
    }
    switch step {
    case let .refuse(refused):
      throw refused
    case let .stream(text), let .drop(text):
      return AsyncThrowingStream { continuation in
        text.utf8.forEach { continuation.yield($0) }
        continuation.finish()
      }
    case let .dropWithError(text):
      return AsyncThrowingStream { continuation in
        text.utf8.forEach { continuation.yield($0) }
        continuation.finish(throwing: URLError(.networkConnectionLost))
      }
    case .hang:
      return AsyncThrowingStream { continuation in
        continuation.onTermination = { [self] _ in lock.withLock { closedFlag = true } }
      }
    }
  }
}
