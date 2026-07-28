import XCTest
@testable import TypeTypeIOS

final class LiveSponsorBlockPolicyTests: XCTestCase {
  func testNormalizesMillisecondsAndUsesCategoryPreference() throws {
    var settings = LiveSettings()
    settings.sponsorBlockCategoryActions["sponsor"] = "mark_only"
    let segment = LivePlaybackSponsorSegment(
      startTime: 55_649,
      endTime: 174_610,
      category: "sponsor",
      action: "skip"
    )

    let window = try XCTUnwrap(
      LiveSponsorBlockPolicy.window(
        for: segment,
        settings: settings,
        duration: 600
      )
    )

    XCTAssertEqual(window.start, 55.649, accuracy: 0.001)
    XCTAssertEqual(window.end, 174.61, accuracy: 0.001)
    XCTAssertEqual(window.action, "mark_only")
  }

  func testFullVideoLabelRequiresManualSkipWhenConfigured() throws {
    var settings = LiveSettings()
    settings.sponsorBlockCategoryActions["exclusive_access"] =
      "auto_skip"
    settings.sponsorBlockManualSkipOnFullVideo = true
    let window = try XCTUnwrap(
      LiveSponsorBlockPolicy.window(
        for: LivePlaybackSponsorSegment(
          startTime: 0,
          endTime: 590,
          category: "exclusive_access",
          action: "skip"
        ),
        settings: settings,
        duration: 600
      )
    )

    XCTAssertTrue(window.isFullVideo)
    XCTAssertFalse(
      LiveSponsorBlockPolicy.shouldAutoSkip(
        window,
        settings: settings,
        streamCategory: nil
      )
    )
  }

  func testNonMusicSegmentRespectsVideoCategory() throws {
    var settings = LiveSettings()
    settings.sponsorBlockCategoryActions["music_offtopic"] =
      "auto_skip"
    settings.sponsorBlockSkipNonMusicOnlyOnMusicVideos = true
    let window = try XCTUnwrap(
      LiveSponsorBlockPolicy.window(
        for: LivePlaybackSponsorSegment(
          startTime: 10,
          endTime: 20,
          category: "music_offtopic",
          action: "skip"
        ),
        settings: settings,
        duration: 600
      )
    )

    XCTAssertFalse(
      LiveSponsorBlockPolicy.shouldAutoSkip(
        window,
        settings: settings,
        streamCategory: "Entertainment"
      )
    )
    XCTAssertTrue(
      LiveSponsorBlockPolicy.shouldAutoSkip(
        window,
        settings: settings,
        streamCategory: "Music"
      )
    )
  }
}
