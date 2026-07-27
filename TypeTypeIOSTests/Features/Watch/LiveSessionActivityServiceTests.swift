import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveSessionActivityServiceTests: XCTestCase {
  private var defaults: UserDefaults!
  private var defaultsSuiteName = ""

  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
    defaultsSuiteName =
      "LiveSessionActivityServiceTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: defaultsSuiteName)
  }

  override func tearDown() {
    defaults?.removePersistentDomain(forName: defaultsSuiteName)
    defaults = nil
    defaultsSuiteName = ""
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testPlaybackLifecycleUsesServerContractAndStableDevice()
    async throws {
    var requests: [URLRequest] = []
    URLProtocolStub.register { request in
      requests.append(request)
      return try Self.response(request, status: 204)
    }
    let service = makeService()
    let playing = snapshot(
      positionMilliseconds: 12_345,
      isPaused: false
    )
    let paused = snapshot(
      positionMilliseconds: 27_000,
      isPaused: true
    )

    try await service.reportPlaybackStart(playing)
    try await service.reportPlaybackProgress(paused)
    try await service.reportPlaybackStop()

    XCTAssertEqual(
      requests.compactMap(\.url?.path),
      [
        "/api/sessions/playback/start",
        "/api/sessions/playback/progress",
        "/api/sessions/playback/stop",
      ]
    )
    XCTAssertEqual(
      requests.map(\.httpMethod),
      ["POST", "POST", "POST"]
    )
    XCTAssertTrue(
      requests.allSatisfy {
        $0.value(forHTTPHeaderField: "Authorization")
          == "Bearer token"
      }
    )

    let start = try Self.jsonBody(requests[0])
    let progress = try Self.jsonBody(requests[1])
    let stop = try Self.jsonBody(requests[2])
    XCTAssertEqual(start["clientName"] as? String, "TypeType iOS")
    XCTAssertEqual(start["videoUrl"] as? String, playing.videoURL)
    XCTAssertEqual(start["title"] as? String, playing.title)
    XCTAssertEqual(start["thumbnail"] as? String, playing.thumbnailURL)
    XCTAssertEqual(start["channelName"] as? String, playing.channelName)
    XCTAssertEqual(
      (start["positionMs"] as? NSNumber)?.int64Value,
      12_345
    )
    XCTAssertEqual(
      (start["durationMs"] as? NSNumber)?.int64Value,
      596_000
    )
    XCTAssertEqual(start["paused"] as? Bool, false)
    XCTAssertEqual(
      (progress["positionMs"] as? NSNumber)?.int64Value,
      27_000
    )
    XCTAssertEqual(progress["paused"] as? Bool, true)

    let deviceID = try XCTUnwrap(start["deviceId"] as? String)
    XCTAssertFalse(deviceID.isEmpty)
    XCTAssertEqual(progress["deviceId"] as? String, deviceID)
    XCTAssertEqual(stop["deviceId"] as? String, deviceID)
    XCTAssertNil(stop["videoUrl"])
  }

  func testGuestPolicySkipsEveryActivityRequest() async throws {
    URLProtocolStub.register { request in
      XCTFail("Guest reporting must not contact \(request.url?.path ?? "")")
      return try Self.response(request, status: 500)
    }
    let service = makeService(canReport: { false })
    let value = snapshot(
      positionMilliseconds: 1_000,
      isPaused: false
    )

    try await service.report()
    try await service.reportPlaybackStart(value)
    try await service.reportPlaybackProgress(value)
    try await service.reportPlaybackStop()
  }

  func testReporterSerializesStartProgressAndStop() async {
    let service = SessionActivityServiceSpy()
    let reporter = LivePlaybackSessionReporter(service: service)
    let playing = snapshot(
      positionMilliseconds: 4_000,
      isPaused: false
    )
    let paused = snapshot(
      positionMilliseconds: 18_000,
      isPaused: true
    )

    reporter.startIfNeeded(playing)
    reporter.startIfNeeded(playing)
    await reporter.waitForPendingOperations()
    reporter.progress(paused)
    await reporter.waitForPendingOperations()
    reporter.stop()
    await reporter.waitForPendingOperations()

    XCTAssertEqual(service.events, ["start", "progress", "stop"])
    XCTAssertEqual(service.snapshots, [playing, paused])
  }

  private func makeService(
    canReport: @escaping () -> Bool = { true }
  ) -> LiveSessionActivityService {
    LiveSessionActivityService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: {
          URL(string: "https://example.test/api")
        },
        accessTokenProvider: { "token" },
        session: Self.session()
      ),
      defaults: defaults,
      canReport: canReport
    )
  }

  private func snapshot(
    positionMilliseconds: Int64,
    isPaused: Bool
  ) -> LivePlaybackActivitySnapshot {
    LivePlaybackActivitySnapshot(
      videoURL: "https://www.youtube.com/watch?v=YE7VzlLtp-4",
      title: "Big Buck Bunny",
      thumbnailURL: "https://example.test/bunny.jpg",
      channelName: "Blender",
      positionMilliseconds: positionMilliseconds,
      durationMilliseconds: 596_000,
      isPaused: isPaused
    )
  }

  private static func session() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    status: Int
  ) throws -> (HTTPURLResponse, Data) {
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(request.url),
        statusCode: status,
        httpVersion: nil,
        headerFields: nil
      )
    )
    return (response, Data())
  }

  private static func jsonBody(
    _ request: URLRequest
  ) throws -> [String: Any] {
    let data = try XCTUnwrap(
      try URLProtocolStub.bodyData(from: request)
    )
    return try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
  }
}

@MainActor
private final class SessionActivityServiceSpy:
  LiveSessionActivityServiceProtocol {
  private(set) var events: [String] = []
  private(set) var snapshots: [LivePlaybackActivitySnapshot] = []

  func report() async throws {
    events.append("activity")
  }

  func reportPlaybackStart(
    _ snapshot: LivePlaybackActivitySnapshot
  ) async throws {
    events.append("start")
    snapshots.append(snapshot)
  }

  func reportPlaybackProgress(
    _ snapshot: LivePlaybackActivitySnapshot
  ) async throws {
    events.append("progress")
    snapshots.append(snapshot)
  }

  func reportPlaybackStop() async throws {
    events.append("stop")
  }
}
