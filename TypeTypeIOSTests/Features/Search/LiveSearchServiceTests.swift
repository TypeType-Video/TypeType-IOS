import XCTest
@testable import TypeTypeIOS

final class LiveSearchServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testSearchSendsExactBackendQueryAndDecodesMixedResults() async throws {
    URLProtocolStub.register { request in
      let components = try XCTUnwrap(
        request.url.flatMap {
          URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }
      )
      XCTAssertEqual(components.path, "/api/search")
      XCTAssertEqual(
        Dictionary(
          uniqueKeysWithValues:
            (components.queryItems ?? []).map { ($0.name, $0.value) }
        ),
        [
          "q": "Big Buck Bunny",
          "service": "0",
          "nextpage": "opaque-page",
          "contentFilter": "|1|videos",
          "sortFilter": "sortby|8|sort_publish_time",
        ]
      )
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer token"
      )
      return try Self.response(request, body: Self.searchBody)
    }

    let page = try await makeService().search(
      query: "Big Buck Bunny",
      serviceID: 0,
      nextPage: "opaque-page",
      contentFilter: "|1|videos",
      sortFilter: "sortby|8|sort_publish_time"
    )

    XCTAssertEqual(page.items.map(\.title), ["Backend video"])
    XCTAssertEqual(page.channels.map(\.name), ["Blender"])
    XCTAssertEqual(page.playlists.map(\.title), ["Open Movies"])
    XCTAssertEqual(page.nextPage, "next")
    XCTAssertEqual(page.searchSuggestion, "Big Buck Bunny")
    XCTAssertTrue(page.isCorrectedSearch)
  }

  func testDiscoveryEndpointsUseServiceContract() async throws {
    var paths: [String] = []
    URLProtocolStub.register { request in
      let url = try XCTUnwrap(request.url)
      paths.append(url.path)
      if url.path.hasSuffix("/search/filters") {
        return try Self.response(
          request,
          body: """
          {"contentFilters":[{"value":"|0|all","label":"all"}],\
          "sortFilters":[]}
          """
        )
      }
      if url.path.hasSuffix("/trending") {
        return try Self.response(
          request,
          body: "[\(Self.videoJSON)]"
        )
      }
      return try Self.response(
        request,
        body: #"["Big Buck Bunny","Big Buck Bunny 4K"]"#
      )
    }
    let service = makeService()

    let filters = try await service.filters(serviceID: 0)
    let suggestions = try await service.suggestions(
      query: "Big",
      serviceID: 0
    )
    let trending = try await service.trending(serviceID: 0)

    XCTAssertEqual(filters.contentFilters.first?.displayName, "All")
    XCTAssertEqual(suggestions, ["Big Buck Bunny", "Big Buck Bunny 4K"])
    XCTAssertEqual(trending.first?.title, "Backend video")
    XCTAssertEqual(
      paths,
      ["/api/search/filters", "/api/suggestions", "/api/trending"]
    )
  }

  private func makeService() -> LiveSearchService {
    LiveSearchService(
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
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    let url = try XCTUnwrap(request.url)
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }

  private static let searchBody = """
  {
    "items":[\(videoJSON)],
    "nextpage":"next",
    "searchSuggestion":"Big Buck Bunny",
    "isCorrectedSearch":true,
    "channels":[{
      "id":"channel-1","name":"Blender","url":"https://youtube.test/c",
      "thumbnailUrl":"https://image.test/c.jpg","description":"Official",
      "subscriberCount":1200,"streamCount":40,"isVerified":true
    }],
    "playlists":[{
      "id":"playlist-1","title":"Open Movies","url":"https://youtube.test/p",
      "thumbnailUrl":"https://image.test/p.jpg","uploaderName":"Blender",
      "streamCount":12,"playlistType":"normal"
    }]
  }
  """

  private static let videoJSON = """
  {
    "id":"video-1","title":"Backend video","url":"https://youtube.test/v",
    "thumbnailUrl":"https://image.test/v.jpg","uploaderName":"Blender",
    "uploaderUrl":"https://youtube.test/c",
    "uploaderAvatarUrl":"https://image.test/a.jpg","duration":596,
    "viewCount":1234,"uploadDate":"today","uploaded":1,
    "streamType":"video_stream","isShortFormContent":false,
    "uploaderVerified":true,"shortDescription":"Real result",
    "publishedAt":1,"isLive":false,"isPostLive":false,
    "isLiveContent":false,"requiresMembership":false
  }
  """
}
