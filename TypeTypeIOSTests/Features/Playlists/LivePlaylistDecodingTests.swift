import Foundation
import XCTest
@testable import TypeTypeIOS

final class LivePlaylistDecodingTests: XCTestCase {
  private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(json.utf8))
  }

  func testVideoItemSurvivesNullAndMissingFields() throws {
    let item = try decode(LiveVideoItem.self, from: """
    {
      "id": "https://www.youtube.com/watch?v=abc",
      "title": null,
      "url": "https://www.youtube.com/watch?v=abc",
      "uploaderName": "Someone",
      "duration": null,
      "viewCount": -1,
      "isLive": null
    }
    """)

    XCTAssertEqual(item.title, "")
    XCTAssertEqual(item.duration, 0)
    XCTAssertEqual(item.viewCount, -1)
    XCTAssertEqual(item.isLive, false)
    XCTAssertEqual(item.canonicalID, "https://www.youtube.com/watch?v=abc")
  }

  func testSavedPlaylistSurvivesNullAndMissingFields() throws {
    let saved = try decode(LiveSavedPlaylist.self, from: """
    {
      "id": "saved-1",
      "publicPlaylistId": null,
      "url": "https://www.youtube.com/playlist?list=PL1",
      "title": "List",
      "streamCount": null
    }
    """)

    XCTAssertEqual(saved.publicPlaylistID, "")
    XCTAssertEqual(saved.streamCount, 0)
    XCTAssertEqual(saved.playlistType, "")
  }

  func testPlaylistResultSurvivesNullAndMissingFields() throws {
    let result = try decode(LivePlaylistResult.self, from: """
    {
      "id": "PL1",
      "title": null,
      "url": "https://www.youtube.com/playlist?list=PL1",
      "streamCount": 12
    }
    """)

    XCTAssertEqual(result.title, "")
    XCTAssertEqual(result.streamCount, 12)
  }

  func testPlaylistPageKeepsGoodRowsBesideBrokenOnes() throws {
    let page = try decode(LivePublicPlaylistPage.self, from: """
    {
      "playlist": {
        "id": "PL1",
        "title": "List",
        "url": "https://www.youtube.com/playlist?list=PL1",
        "thumbnailUrl": "",
        "uploaderName": "Owner",
        "streamCount": 2,
        "playlistType": "playlist"
      },
      "videos": [
        {
          "id": "v1",
          "title": "Good row",
          "url": "https://www.youtube.com/watch?v=v1",
          "thumbnailUrl": "",
          "uploaderName": "A",
          "uploaderUrl": "",
          "uploaderAvatarUrl": "",
          "duration": 10,
          "viewCount": 1,
          "uploadDate": "",
          "uploaded": 1,
          "streamType": "video",
          "isShortFormContent": false,
          "uploaderVerified": false,
          "isLive": false,
          "isPostLive": false,
          "isLiveContent": false,
          "requiresMembership": false
        },
        {
          "id": "v2",
          "title": null,
          "url": "https://www.youtube.com/watch?v=v2",
          "duration": null
        }
      ],
      "nextpage": null
    }
    """)

    XCTAssertEqual(page.videos.count, 2)
    XCTAssertEqual(page.videos[0].title, "Good row")
    XCTAssertEqual(page.videos[1].title, "")
  }
}
