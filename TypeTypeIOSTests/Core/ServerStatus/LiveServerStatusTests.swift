import XCTest
@testable import TypeTypeIOS

final class LiveServerStatusTests: XCTestCase {
  func testARestartThenANewBootCountsAsOneResume() throws {
    var status = LiveServerStatus()
    status.greeted(try hello(#"{"bootId":"a"}"#))
    XCTAssertEqual(status.resumes, 0)
    status.announced(try notice(#"{"kind":"restart","issuedAt":1}"#))
    XCTAssertEqual(status.phase, .restarting)
    status.lost()
    status.lossConfirmed()
    XCTAssertEqual(status.phase, .restarting)
    status.greeted(try hello(#"{"bootId":"b"}"#))
    XCTAssertEqual(status.phase, .online)
    XCTAssertEqual(status.resumes, 1)
  }

  func testALossBecomesUnreachableAndAQuietStreamEndsIt() {
    var status = LiveServerStatus()
    status.lost()
    status.lossConfirmed()
    XCTAssertEqual(status.phase, .unreachable)
    status.reached()
    XCTAssertEqual(status.phase, .online)
    XCTAssertEqual(status.resumes, 1)
  }

  func testDecodesTheStreamEvents() {
    XCTAssertEqual(LiveServerEventsService.decode(LiveSSEEvent(name: "clear", data: "{}")), .cleared)
    if case let .notice(notice) = LiveServerEventsService.decode(LiveSSEEvent(name: "notice", data: #"{"kind":"maintenance","message":"  Back soon ","issuedAt":2}"#)) {
      XCTAssertEqual(notice.kind, .maintenance)
      XCTAssertEqual(notice.trimmedMessage, "Back soon")
    } else {
      XCTFail("Expected a notice")
    }
    XCTAssertNil(LiveServerEventsService.decode(LiveSSEEvent(name: "notice", data: #"{"kind":"party"}"#)))
  }

  private func hello(_ json: String) throws -> LiveServerHello {
    try JSONDecoder().decode(LiveServerHello.self, from: Data(json.utf8))
  }

  private func notice(_ json: String) throws -> LiveServerNotice {
    try JSONDecoder().decode(LiveServerNotice.self, from: Data(json.utf8))
  }
}

final class LiveServerEventsServiceTests: XCTestCase {
  func testReconnectsAfterADropAndStopsOnA404() async {
    let transport = EventsTransport()
    let service = LiveServerEventsService(transport: transport) { wait in
      if wait == LiveServerEventsService.helloWait { try await Task.sleep(for: .seconds(30)) }
    }
    var events: [LiveServerEvent] = []
    for await event in service.events() { events.append(event) }
    XCTAssertEqual(events.count, 3)
    if case .hello = events.first {} else { XCTFail("Expected the hello first") }
    XCTAssertEqual(events[1], .lost)
  }
}

@MainActor
final class LiveServerStatusMonitorTests: XCTestCase {
  func testShowsTheNoticeWithItsMessageAndTheReturn() throws {
    let monitor = LiveServerStatusMonitor(service: LiveServerEventsService(transport: EventsTransport())) { _ in
      try await Task.sleep(for: .seconds(60))
    }
    monitor.apply(.notice(try JSONDecoder().decode(LiveServerNotice.self, from: Data(#"{"kind":"update","message":"Ten minutes."}"#.utf8))))
    XCTAssertEqual(monitor.message, "A server update is coming. Playback will resume by itself. Ten minutes.")
    monitor.apply(.cleared)
    XCTAssertNil(monitor.message)
    monitor.apply(.lost)
    monitor.apply(.hello(try JSONDecoder().decode(LiveServerHello.self, from: Data(#"{"bootId":"b"}"#.utf8))))
    XCTAssertNil(monitor.message)
  }
}

private final class EventsTransport: LiveServerEventsTransport, @unchecked Sendable {
  private let lock = NSLock()
  private var calls = 0

  func openServerEvents() async throws -> AsyncThrowingStream<UInt8, Error> {
    let call = lock.withLock { calls += 1; return calls }
    if call > 2 { throw LiveChatRefused(status: 404, retryAfter: nil) }
    let text = call == 1 ? "event: hello\ndata: {\"bootId\":\"a\"}\n\n" : ""
    return AsyncThrowingStream { continuation in
      for byte in Array(text.utf8) { continuation.yield(byte) }
      continuation.finish()
    }
  }
}
