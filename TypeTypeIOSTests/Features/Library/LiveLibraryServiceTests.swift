import XCTest
@testable import TypeTypeIOS

final class LiveLibraryServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testFavoriteRoutesDecodeLegacyDefaults() async throws {
    var methods: [String] = []
    URLProtocolStub.register { request in
      methods.append(request.httpMethod ?? "")
      let path = request.url?.path ?? ""
      if request.httpMethod == "GET", path == "/api/favorites" {
        return try Self.response(
          request,
          status: 200,
          body: """
          [{"videoUrl":"https://video.test/1","favoritedAt":12}]
          """
        )
      }
      if request.httpMethod == "POST" {
        return try Self.response(
          request,
          status: 201,
          body: """
          {"videoUrl":"https://video.test/1","favoritedAt":13}
          """
        )
      }
      return try Self.response(request, status: 204, body: "")
    }
    let service = makeService()

    let favorites = try await service.favorites()
    _ = try await service.addFavorite(videoURL: "https://video.test/1")
    try await service.removeFavorite(videoURL: "https://video.test/1")

    XCTAssertEqual(favorites.first?.title, "")
    XCTAssertEqual(methods, ["GET", "POST", "DELETE"])
  }

  func testWatchLaterPostsCompleteVideoMetadata() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/watch-later")
      XCTAssertEqual(request.httpMethod, "POST")
      let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
      let payload = try JSONSerialization.jsonObject(with: body)
        as? [String: Any]
      XCTAssertEqual(payload?["title"] as? String, "Fixture")
      XCTAssertEqual(payload?["channelName"] as? String, "TypeType")
      return try Self.response(
        request,
        status: 201,
        body: """
        {
          "url":"https://video.test/1","title":"Fixture",
          "thumbnail":"","duration":42,"addedAt":12,
          "channelName":"TypeType","channelUrl":"",
          "channelAvatar":"","viewCount":10,"publishedAt":1
        }
        """
      )
    }
    let video = LiveVideoItemFixture.make(
      url: "https://video.test/1",
      title: "Fixture",
      publishedAt: 1
    )

    let saved = try await makeService().addWatchLater(video: video)

    XCTAssertEqual(saved.addedAt, 12)
  }

  private func makeService() -> LiveLibraryService {
    LiveLibraryService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: { URL(string: "https://example.test/api") },
        accessTokenProvider: { "token" },
        session: Self.session()
      )
    )
  }

  private static func session() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    status: Int,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(request.url),
        statusCode: status,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }
}
