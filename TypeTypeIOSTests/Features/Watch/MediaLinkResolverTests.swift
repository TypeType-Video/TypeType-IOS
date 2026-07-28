import XCTest
@testable import TypeTypeIOS

final class MediaLinkResolverTests: XCTestCase {
  func testSupportedVideoServicesResolveInsideTypeType() {
    let links = [
      DemoWatchLinkCatalog.youtube,
      DemoWatchLinkCatalog.nicoNico,
      DemoWatchLinkCatalog.biliBili,
    ]

    for link in links {
      XCTAssertNotNil(
        DemoMediaLinkResolver.internalVideo(for: link),
        "\(link.host ?? "Unknown host") should resolve internally."
      )
    }
  }

  func testUnrelatedWebsiteRemainsExternal() {
    XCTAssertNil(
      DemoMediaLinkResolver.internalVideo(
        for: DemoBigBuckBunnySource.projectURL
      )
    )
  }

  func testLiveVideoLinksResolveInsideTypeType() throws {
    for value in [
      "https://www.youtube.com/watch?v=YE7VzlLtp-4",
      "https://www.nicovideo.jp/watch/sm9",
      "https://www.bilibili.com/video/BV1xx411c7mD",
    ] {
      let url = try XCTUnwrap(URL(string: value))
      guard case let .video(video) = LiveMediaLinkResolver.destination(
        for: url
      ) else {
        return XCTFail("\(value) should resolve as an internal video.")
      }
      XCTAssertEqual(video.url, value)
    }
  }

  func testLiveChannelAndPlaylistLinksResolveInsideTypeType() throws {
    let channelURL = try XCTUnwrap(
      URL(string: "https://www.youtube.com/@BlenderOfficial")
    )
    guard case let .channel(channel) = LiveMediaLinkResolver.destination(
      for: channelURL
    ) else {
      return XCTFail("The channel should resolve inside TypeType.")
    }
    XCTAssertEqual(channel, channelURL.absoluteString)

    let playlistURL = try XCTUnwrap(
      URL(string: "https://www.youtube.com/playlist?list=PL123")
    )
    guard case let .playlist(playlist) = LiveMediaLinkResolver.destination(
      for: playlistURL
    ) else {
      return XCTFail("The playlist should resolve inside TypeType.")
    }
    XCTAssertEqual(playlist.url, playlistURL.absoluteString)
  }

  func testLiveUnrelatedWebsiteRemainsExternal() throws {
    let url = try XCTUnwrap(
      URL(string: "https://peach.blender.org/")
    )
    XCTAssertNil(LiveMediaLinkResolver.destination(for: url))
  }

  func testTypeTypeWatchAndShortsLinksResolveAsNormalVideos() throws {
    let serverURL = try XCTUnwrap(
      URL(string: "https://beta.typetype.video/api")
    )
    let links = [
      (
        "https://beta.typetype.video/watch?v=sm9",
        "https://www.nicovideo.jp/watch/sm9"
      ),
      (
        "https://beta.typetype.video/shorts?v=YE7VzlLtp-4",
        "https://www.youtube.com/watch?v=YE7VzlLtp-4"
      ),
      (
        "https://beta.typetype.video/watch?v=BV1xx411c7mD",
        "https://www.bilibili.com/video/BV1xx411c7mD"
      ),
    ]

    for (value, expectedSource) in links {
      let url = try XCTUnwrap(URL(string: value))
      guard case let .video(video) = LiveMediaLinkResolver.destination(
        for: url,
        serverURL: serverURL
      ) else {
        return XCTFail("\(value) should resolve as an internal video.")
      }
      XCTAssertEqual(video.url, expectedSource)
      XCTAssertFalse(video.isShortFormContent)
    }
  }

  func testTypeTypeChannelAndPlaylistLinksResolveInternally() throws {
    let serverURL = try XCTUnwrap(
      URL(string: "https://watch.typetype.video/api")
    )
    let channelURL = try XCTUnwrap(
      URL(
        string: "https://watch.typetype.video/channel?url=%40BlenderOfficial"
      )
    )
    guard case let .channel(channel) = LiveMediaLinkResolver.destination(
      for: channelURL,
      serverURL: serverURL
    ) else {
      return XCTFail("The TypeType channel link should stay in-app.")
    }
    XCTAssertEqual(
      channel,
      "https://www.youtube.com/@BlenderOfficial"
    )

    let playlistURL = try XCTUnwrap(
      URL(
        string: "https://watch.typetype.video/playlist?list=PL123"
      )
    )
    guard case let .playlist(playlist) =
      LiveMediaLinkResolver.destination(
        for: playlistURL,
        serverURL: serverURL
      )
    else {
      return XCTFail("The TypeType playlist link should stay in-app.")
    }
    XCTAssertEqual(
      playlist.url,
      "https://www.youtube.com/playlist?list=PL123"
    )
  }

  func testCustomSchemeCanOpenProviderLinks() throws {
    for (value, expectedSource) in [
      (
        "typetype://watch?v=sm9",
        "https://www.nicovideo.jp/watch/sm9"
      ),
      (
        "typetype://watch?v=YE7VzlLtp-4",
        "https://www.youtube.com/watch?v=YE7VzlLtp-4"
      ),
      (
        "typetype://watch?v=BV1xx411c7mD",
        "https://www.bilibili.com/video/BV1xx411c7mD"
      ),
    ] {
      let url = try XCTUnwrap(URL(string: value))
      guard case let .video(video) = LiveMediaLinkResolver.destination(
        for: url
      ) else {
        return XCTFail("\(value) should resolve inside TypeType.")
      }
      XCTAssertEqual(video.url, expectedSource)
    }
  }

  func testAnotherTypeTypeOriginIsNotTrustedAsCurrentServer() throws {
    let link = try XCTUnwrap(
      URL(string: "https://other.example/watch?v=YE7VzlLtp-4")
    )
    let serverURL = try XCTUnwrap(
      URL(string: "https://beta.typetype.video/api")
    )
    XCTAssertNil(
      LiveMediaLinkResolver.destination(
        for: link,
        serverURL: serverURL
      )
    )
  }

  func testRichTextCreatesSeekAndWebLinks() {
    let text =
      "Compare 1:44 with https://www.youtube.com/watch?v=YE7VzlLtp-4"
    let attributed = RichTextParser.attributed(text)
    let links = attributed.runs.compactMap(\.link)

    XCTAssertEqual(links.count, 2)
    let seek = links.first { $0.scheme == "typetype" }
    XCTAssertEqual(
      seek.flatMap(RichTextParser.seekSeconds(from:)),
      104
    )
    XCTAssertTrue(
      links.contains { $0.host == "www.youtube.com" }
    )
  }

  func testHourTimestampIsConvertedToSeconds() {
    let attributed = RichTextParser.attributed("Resume at 1:02:03")
    let seek = attributed.runs.compactMap(\.link).first

    XCTAssertEqual(
      seek.flatMap(RichTextParser.seekSeconds(from:)),
      3_723
    )
  }
}
