import Foundation
import XCTest
@testable import TypeTypeIOS

final class HomeFeedServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testRecommendationsUsesCurrentCursorContract() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer access-token"
      )
      XCTAssertEqual(request.url?.path, "/api/recommendations/home")
      let values = URLComponents(
        url: try XCTUnwrap(request.url),
        resolvingAgainstBaseURL: false
      )?.queryItems?.reduce(into: [String: String]()) {
        $0[$1.name] = $1.value
      }
      XCTAssertEqual(values?["service"], "5")
      XCTAssertEqual(values?["limit"], "60")
      XCTAssertEqual(values?["intent"], "deep")
      XCTAssertEqual(values?["cursor"], "next page+/=")
      XCTAssertNil(values?["nextCursor"])
      return try Self.response(
        request,
        body: Self.pageJSON
      )
    }

    let page = try await makeService().recommendations(
      serviceID: 5,
      intent: "deep",
      limit: 120,
      cursor: "next page+/="
    )

    XCTAssertEqual(page.items.count, 1)
    XCTAssertEqual(page.items[0].uploaderName, "Blender Studio")
    XCTAssertEqual(page.nextCursor, "cursor-2")
    XCTAssertTrue(page.hasMore)
  }

  func testRecommendationsRequiresAccessToken() async {
    let client = URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: { nil },
      session: Self.makeSession()
    )
    do {
      _ = try await HomeFeedService(apiClient: client)
        .recommendations(
          serviceID: 0,
          intent: "auto",
          limit: 30,
          cursor: nil
        )
      XCTFail("Expected a missing-token error.")
    } catch let error as NetworkError {
      guard case .missingAccessToken = error else {
        return XCTFail("Expected missingAccessToken.")
      }
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  private func makeService() -> HomeFeedService {
    let client = URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: { "access-token" },
      session: Self.makeSession()
    )
    return HomeFeedService(apiClient: client)
  }

  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw HomeServiceTestError.missingURL
    }
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw HomeServiceTestError.invalidResponse
    }
    return (response, Data(body.utf8))
  }

  private static let pageJSON = """
    {
      "items": [{
        "id": "video-1",
        "title": "Big Buck Bunny",
        "url": "https://www.youtube.com/watch?v=video-1",
        "thumbnailUrl": "https://i.ytimg.com/vi/video-1/hqdefault.jpg",
        "uploaderName": "Blender Studio",
        "uploaderUrl": "https://www.youtube.com/@blenderstudio",
        "uploaderAvatarUrl": "https://example.test/avatar.jpg",
        "duration": 596,
        "viewCount": 12345,
        "uploadDate": "2026-07-26",
        "uploaded": -1,
        "streamType": "VIDEO_STREAM",
        "isShortFormContent": false,
        "uploaderVerified": true,
        "shortDescription": "Open movie",
        "publishedAt": 1785063770906,
        "isLive": false,
        "isPostLive": false,
        "isLiveContent": false,
        "requiresMembership": false
      }],
      "nextCursor": "cursor-2",
      "hasMore": true,
      "debug": {"source": "test"}
    }
    """
}

private enum HomeServiceTestError: Error {
  case missingURL
  case invalidResponse
}
