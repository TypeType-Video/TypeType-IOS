import XCTest
@testable import TypeTypeIOS

final class LiveAudioSelectionTests: XCTestCase {
  func testSameLanguagePicksTheSameTrackWhateverTheOrder() {
    let service = LivePlaybackService(apiClient: SelectionAPIClientStub(), serverURLProvider: { nil })
    let low = Self.audio(itag: 599, bitrate: 31_000)
    let normal = Self.audio(itag: 140, bitrate: 130_000)

    for order in [[low, normal], [normal, low]] {
      for _ in 0..<20 {
        XCTAssertEqual(service.selectAudio(from: order, requestedTrackID: "en-US.4")?.itag, 140)
        XCTAssertEqual(service.selectAudio(from: order, requestedTrackID: nil)?.itag, 140)
      }
    }
  }

  private static func audio(itag: Int, bitrate: Int) -> LivePlaybackAudioSource {
    LivePlaybackAudioSource(
      url: "https://sabr.example.com/\(itag)",
      mimeType: "audio/mp4",
      bitrate: bitrate,
      codec: "mp4a.40.2",
      quality: nil,
      itag: itag,
      audioTrackID: "en-US.4",
      audioTrackName: "English",
      audioLocale: "en-US",
      isOriginal: true,
      contentLength: 0,
      initStart: 0,
      initEnd: 0,
      indexStart: 0,
      indexEnd: 0,
      deliveryMethod: "sabr",
      manifestURL: nil
    )
  }
}

private final class SelectionAPIClientStub: APIClient {
  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
    throw NetworkError.invalidResponse
  }

  func request(_ endpoint: APIEndpoint) async throws {}

  func requestData(_ endpoint: APIEndpoint) async throws -> Data {
    Data()
  }
}
