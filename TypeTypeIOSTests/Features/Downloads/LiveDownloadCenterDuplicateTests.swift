import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveDownloadCenterDuplicateTests: XCTestCase {
  func testActiveVideoDownloadBlocksDuplicateButAllowsAudio()
    async throws
  {
    let context = try Self.makeContext()
    _ = try await context.center.start(
      video: Self.video,
      options: Self.videoOptions
    )

    do {
      _ = try await context.center.start(
        video: Self.video,
        options: Self.videoOptions
      )
      XCTFail("Expected a duplicate download error.")
    } catch let error as LiveDownloadCenterError {
      XCTAssertEqual(
        error.errorDescription,
        "A video download for this video is already active."
      )
    }

    XCTAssertEqual(context.service.createdOptions.count, 1)

    _ = try await context.center.start(
      video: Self.video,
      options: Self.audioOptions
    )
    XCTAssertEqual(context.service.createdOptions.count, 2)
    XCTAssertEqual(context.center.visibleRecords.count, 2)
  }

  func testDownloadViewModelAdoptsExistingActiveDownload()
    async throws
  {
    let context = try Self.makeContext()
    let started = try await context.center.start(
      video: Self.video,
      options: Self.videoOptions
    )

    let viewModel = LiveDownloadViewModel(
      video: Self.video,
      center: context.center
    )

    XCTAssertEqual(viewModel.state, .tracking)
    XCTAssertEqual(viewModel.job?.id, started.job.id)
    await viewModel.start()
    XCTAssertEqual(context.service.createdOptions.count, 1)
  }
}

private extension LiveDownloadCenterDuplicateTests {
  struct Context {
    let center: LiveDownloadCenter
    let service: DownloadServiceStub
  }

  static let video = LiveVideoItem(
    id: "mcV4qoX2MIE",
    title: "Download test",
    url: "https://www.youtube.com/watch?v=mcV4qoX2MIE",
    thumbnailURL: "",
    uploaderName: "TypeType",
    uploaderURL: "",
    uploaderAvatarURL: "",
    duration: 120,
    viewCount: 1,
    uploadDate: "",
    uploaded: 0,
    streamType: "VIDEO_STREAM",
    isShortFormContent: false,
    uploaderVerified: false,
    shortDescription: nil,
    publishedAt: nil,
    isLive: false,
    isPostLive: false,
    isLiveContent: false,
    requiresMembership: false
  )

  static let videoOptions = LiveDownloadOptions(
    mode: "video",
    quality: "1080p",
    format: "mp4",
    allowQualityFallback: true,
    sponsorBlock: true,
    sponsorBlockCategories: ["sponsor"],
    thumbnailOnly: false,
    subtitles: LiveDownloadSubtitleOptions(
      enabled: false,
      auto: false,
      embed: false,
      languages: [],
      format: "vtt"
    )
  )

  static let audioOptions = LiveDownloadOptions(
    mode: "audio",
    quality: "best",
    format: "m4a",
    allowQualityFallback: true,
    sponsorBlock: false,
    sponsorBlockCategories: [],
    thumbnailOnly: false,
    subtitles: LiveDownloadSubtitleOptions(
      enabled: false,
      auto: false,
      embed: false,
      languages: [],
      format: "vtt"
    )
  )

  static func makeContext() throws -> Context {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let service = DownloadServiceStub()
    let center = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    return Context(center: center, service: service)
  }
}
