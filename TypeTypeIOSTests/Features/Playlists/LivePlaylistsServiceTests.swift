import XCTest
@testable import TypeTypeIOS

final class LivePlaylistsServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testCreateUpdateAndDeleteUsePlaylistContract() async throws {
    var requests: [URLRequest] = []
    URLProtocolStub.register { request in
      requests.append(request)
      if request.httpMethod == "POST" {
        return try Self.response(
          request,
          status: 201,
          body: """
          {"id":"playlist-1","name":"Native","description":"iOS",\
          "videos":[],"videoCount":0,"createdAt":12}
          """
        )
      }
      return try Self.response(request, status: 204, body: "")
    }
    let service = makeService()

    let playlist = try await service.create(
      name: "Native",
      description: "iOS"
    )
    try await service.update(
      id: playlist.id,
      name: "Renamed",
      description: "Updated"
    )
    try await service.delete(id: playlist.id)

    XCTAssertEqual(playlist.name, "Native")
    XCTAssertEqual(requests.map(\.httpMethod), ["POST", "PUT", "DELETE"])
    let updateBody = try XCTUnwrap(
      URLProtocolStub.bodyData(from: requests[1])
    )
    let update = try JSONSerialization.jsonObject(with: updateBody)
      as? [String: String]
    XCTAssertEqual(update?["name"], "Renamed")
  }

  func testAddRemoveAndReorderUseVideoURLs() async throws {
    var requests: [URLRequest] = []
    URLProtocolStub.register { request in
      requests.append(request)
      if request.httpMethod == "POST" {
        return try Self.response(
          request,
          status: 201,
          body: Self.playlistVideoJSON
        )
      }
      return try Self.response(request, status: 204, body: "")
    }
    let service = makeService()
    let video = LiveVideoItemFixture.make(
      url: "https://video.test/1",
      title: "Fixture"
    )

    _ = try await service.addVideo(id: "playlist-1", video: video)
    try await service.reorder(
      id: "playlist-1",
      videoURLs: ["https://video.test/1"]
    )
    try await service.removeVideo(
      id: "playlist-1",
      videoURL: "https://video.test/1"
    )

    XCTAssertEqual(requests.map(\.httpMethod), ["POST", "PUT", "DELETE"])
    let reorderBody = try XCTUnwrap(
      URLProtocolStub.bodyData(from: requests[1])
    )
    let payload = try JSONSerialization.jsonObject(with: reorderBody)
      as? [String: [String]]
    XCTAssertEqual(payload?["order"], ["https://video.test/1"])
  }

  func testSavedAndPublicPlaylistContracts() async throws {
    var paths: [String] = []
    URLProtocolStub.register { request in
      paths.append(request.url?.path ?? "")
      if request.url?.path == "/api/saved-playlists" {
        return try Self.response(
          request,
          status: 200,
          body: "[\(Self.savedJSON)]"
        )
      }
      return try Self.response(
        request,
        status: 200,
        body: """
        {"playlist":\(Self.publicPlaylistJSON),\
        "videos":[],"nextpage":"opaque"}
        """
      )
    }
    let service = makeService()

    let saved = try await service.savedPlaylists()
    let page = try await service.publicPlaylist(
      url: "https://youtube.test/playlist",
      nextPage: "next"
    )

    XCTAssertEqual(saved.first?.title, "Saved")
    XCTAssertEqual(page.nextPage, "opaque")
    XCTAssertEqual(paths, ["/api/saved-playlists", "/api/playlist"])
  }

  private func makeService() -> LivePlaylistsService {
    LivePlaylistsService(
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

  private static let playlistVideoJSON = """
  {
    "id":"video-1","url":"https://video.test/1","title":"Fixture",
    "thumbnail":"","duration":42,"position":0,"channelName":"TypeType",
    "channelUrl":"","channelAvatar":"","viewCount":10,"addedAt":12,
    "publishedAt":1,"watchPosition":0,"watched":false,
    "progressUpdatedAt":0
  }
  """

  private static let savedJSON = """
  {
    "id":"saved-1","publicPlaylistId":"public-1",
    "url":"https://youtube.test/playlist","title":"Saved",
    "thumbnailUrl":"","uploaderName":"TypeType","streamCount":12,
    "playlistType":"normal","savedAt":12
  }
  """

  private static let publicPlaylistJSON = """
  {
    "id":"public-1","title":"Public",
    "url":"https://youtube.test/playlist","thumbnailUrl":"",
    "uploaderName":"TypeType","streamCount":12,
    "playlistType":"normal"
  }
  """
}
