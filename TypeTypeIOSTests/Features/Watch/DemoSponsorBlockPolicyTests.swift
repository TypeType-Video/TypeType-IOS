import XCTest
@testable import TypeTypeIOS

final class DemoSponsorBlockPolicyTests: XCTestCase {
  private let regular = DemoSponsorBlockSegment(
    category: "sponsor",
    start: 4,
    end: 18,
    isFullVideo: false
  )
  private let fullVideo = DemoSponsorBlockSegment(
    category: "exclusive_access",
    start: 0,
    end: 596,
    isFullVideo: true
  )
  private let nonMusic = DemoSponsorBlockSegment(
    category: "music_offtopic",
    start: 4,
    end: 18,
    isFullVideo: false
  )

  func testMinimumDurationAndVisibilityRules() {
    XCTAssertTrue(
      DemoSponsorBlockPolicy.isVisible(
        regular,
        action: "Mark",
        minimumDuration: 10,
        showsFullVideoLabels: true
      )
    )
    XCTAssertFalse(
      DemoSponsorBlockPolicy.isVisible(
        regular,
        action: "Mark",
        minimumDuration: 15,
        showsFullVideoLabels: true
      )
    )
    XCTAssertFalse(
      DemoSponsorBlockPolicy.isVisible(
        fullVideo,
        action: "Mark",
        minimumDuration: 0,
        showsFullVideoLabels: false
      )
    )
  }

  func testFullVideoManualSkipPreventsAutomaticAdvance() {
    XCTAssertFalse(
      autoSkips(fullVideo, manualFullVideoSkip: true)
    )
    XCTAssertTrue(
      autoSkips(fullVideo, manualFullVideoSkip: false)
    )
  }

  func testNonMusicRuleOnlyAutoSkipsOnMusicVideosWhenRequested() {
    XCTAssertFalse(
      autoSkips(
        nonMusic,
        skipsNonMusicOnlyOnMusicVideos: true,
        isMusicVideo: false
      )
    )
    XCTAssertTrue(
      autoSkips(
        nonMusic,
        skipsNonMusicOnlyOnMusicVideos: true,
        isMusicVideo: true
      )
    )
  }

  private func autoSkips(
    _ segment: DemoSponsorBlockSegment,
    manualFullVideoSkip: Bool = false,
    skipsNonMusicOnlyOnMusicVideos: Bool = false,
    isMusicVideo: Bool = false
  ) -> Bool {
    DemoSponsorBlockPolicy.shouldAutoSkip(
      segment,
      action: "Skip",
      minimumDuration: 0,
      manualFullVideoSkip: manualFullVideoSkip,
      skipsNonMusicOnlyOnMusicVideos: skipsNonMusicOnlyOnMusicVideos,
      isMusicVideo: isMusicVideo
    )
  }
}
