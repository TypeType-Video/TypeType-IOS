import XCTest
@testable import TypeTypeIOS

final class LiveChannelServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testChannelPageUsesPostBodyAndDecodesMetadata() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/channel/page")
      XCTAssertEqual(request.httpMethod, "POST")
      let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
      let payload = try JSONDecoder().decode(
        ChannelPayload.self,
        from: body
      )
      XCTAssertEqual(payload.url, "https://youtube.test/channel")
      XCTAssertEqual(payload.nextpage, "opaque")
      XCTAssertEqual(payload.sort, "popular")
      return try Self.response(
        request,
        body: """
        {
          "name":"Blender","description":"Official",
          "avatarUrl":"https://image.test/avatar.jpg",
          "bannerUrl":"https://image.test/banner.jpg",
          "subscriberCount":1200,"isVerified":true,
          "videos":[\(Self.videoJSON)],"nextpage":"next"
        }
        """
      )
    }

    let page = try await makeService().channel(
      url: "https://youtube.test/channel",
      nextPage: "opaque",
      sort: .popular
    )

    XCTAssertEqual(page.name, "Blender")
    XCTAssertEqual(page.videos.first?.title, "Channel video")
    XCTAssertEqual(page.nextPage, "next")
  }

  func testPlaylistsAndPodcastsUseOpaquePagination() async throws {
    var paths: [String] = []
    URLProtocolStub.register { request in
      let url = try XCTUnwrap(request.url)
      paths.append(url.path)
      XCTAssertTrue(url.query?.contains("nextpage=opaque") == true)
      if url.path.hasSuffix("/channel/playlists") {
        return try Self.response(
          request,
          body: """
          {"playlists":[],"nextpage":null}
          """
        )
      }
      if url.path.hasSuffix("/podcasts/episodes") {
        return try Self.response(
          request,
          body: """
          {
            "podcast":{
              "id":"podcast","title":"Open Movies",
              "url":"https://youtube.test/podcast","thumbnailUrl":"",
              "uploaderName":"Blender","streamCount":5,
              "playlistType":"podcast"
            },
            "episodes":[\(Self.videoJSON)],"nextpage":null
          }
          """
        )
      }
      return try Self.response(
        request,
        body: """
        {"channelName":"Blender","channelUrl":"https://youtube.test/channel",\
        "podcasts":[],"episodes":[],"nextpage":null}
        """
      )
    }
    let service = makeService()

    _ = try await service.playlists(
      url: "https://youtube.test/channel",
      nextPage: "opaque"
    )
    _ = try await service.podcasts(
      url: "https://youtube.test/channel",
      nextPage: "opaque"
    )
    let episodes = try await service.podcastEpisodes(
      url: "https://youtube.test/podcast",
      nextPage: "opaque"
    )

    XCTAssertEqual(
      paths,
      [
        "/api/channel/playlists",
        "/api/podcasts",
        "/api/podcasts/episodes",
      ]
    )
    XCTAssertEqual(episodes.episodes.first?.title, "Channel video")
  }

  func testYoutubeChannelRequestBuilderSupportsSearchAndLive() {
    let url = "https://www.youtube.com/channel/UC123"
    XCTAssertEqual(
      LiveChannelRequestURLBuilder.build(
        channelURL: url,
        query: "SABR player",
        tab: .videos
      ),
      "https://www.youtube.com/channel/UC123/search?query=SABR%20player"
    )
    XCTAssertEqual(
      LiveChannelRequestURLBuilder.build(
        channelURL: url,
        query: "",
        tab: .live
      ),
      "https://www.youtube.com/channel/UC123/streams"
    )
  }

  private func makeService() -> LiveChannelService {
    LiveChannelService(
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
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(request.url),
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }

  private static let videoJSON = """
  {
    "id":"video","title":"Channel video","url":"https://youtube.test/v",
    "thumbnailUrl":"","uploaderName":"Blender","uploaderUrl":"",
    "uploaderAvatarUrl":"","duration":42,"viewCount":12,
    "uploadDate":"today","uploaded":1,"streamType":"video_stream",
    "isShortFormContent":false,"uploaderVerified":true,
    "shortDescription":null,"publishedAt":1,"isLive":false,
    "isPostLive":false,"isLiveContent":false,
    "requiresMembership":false
  }
  """
}

private struct ChannelPayload: Decodable {
  let url: String
  let nextpage: String?
  let sort: String
}
