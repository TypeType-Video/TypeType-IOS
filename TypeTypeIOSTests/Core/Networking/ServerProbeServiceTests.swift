import Foundation
import XCTest
@testable import TypeTypeIOS

final class ServerProbeServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testProbesInstanceContract() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.absoluteString, "https://host.test/api/instance")
      XCTAssertEqual(
        request.cachePolicy,
        .reloadIgnoringLocalCacheData
      )
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Cache-Control"),
        "no-cache"
      )
      guard let url = request.url else {
        throw ProbeTestError.missingURL
      }
      guard let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      ) else {
        throw ProbeTestError.invalidResponse
      }
      return (response, Data(Self.instanceJSON.utf8))
    }

    let service = ServerProbeService(session: Self.makeSession())
    let metadata = try await service.probe(
      baseURL: try XCTUnwrap(URL(string: "https://host.test/api"))
    )

    XCTAssertEqual(metadata.name, "TypeType")
    XCTAssertEqual(metadata.version, "0.1.0-test")
    XCTAssertEqual(metadata.apiVersion, 1)
    XCTAssertTrue(metadata.guestAllowed)
    XCTAssertEqual(metadata.supportedServices, [0, 3, 4])
    XCTAssertTrue(metadata.oidcEnabled)
    XCTAssertEqual(metadata.oidcProviderName, "Pocket ID")
  }

  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static let instanceJSON = """
    {
      "name": "TypeType",
      "tagline": "Private video",
      "version": "0.1.0-test",
      "apiVersion": 1,
      "registrationAllowed": true,
      "guestAllowed": true,
      "supportedServices": [0, 3, 4],
      "minClientVersion": {"android": null},
      "logoUrl": null,
      "bannerUrl": null,
      "localLoginEnabled": true,
      "oidcEnabled": true,
      "oidcProviderName": "Pocket ID",
      "oidcAutoRedirect": false,
      "youtubeRemoteLoginEnabled": false,
      "youtubeRemoteLoginReady": false,
      "youtubeRemoteLoginUnavailableReason": "disabled",
      "androidPlayback": {
        "supported": true,
        "contractVersion": 4,
        "youtube": {
          "vod": true,
          "live": false,
          "subtitles": true,
          "deferredSubtitleContent": true,
          "bootstrapSubtitleDescriptors": true
        }
      }
    }
    """
}

private enum ProbeTestError: Error {
  case missingURL
  case invalidResponse
}
