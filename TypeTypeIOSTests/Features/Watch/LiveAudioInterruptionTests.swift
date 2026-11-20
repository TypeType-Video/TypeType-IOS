import AVFoundation
import XCTest
@testable import TypeTypeIOS

final class LiveAudioInterruptionTests: XCTestCase {
  func testReadsTheInterruptionAndWhetherToResume() {
    XCTAssertEqual(LiveAudioInterruption([AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]), .began)
    XCTAssertEqual(
      LiveAudioInterruption([
        AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
        AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue,
      ]),
      .ended(shouldResume: true)
    )
    XCTAssertEqual(
      LiveAudioInterruption([AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]),
      .ended(shouldResume: false)
    )
    XCTAssertEqual(LiveAudioInterruption(nil), .unknown)
  }

  func testBackgroundCapsTheVideoOnceAndRestoresTheChoice() {
    var rate = LiveBackgroundBitRate()
    XCTAssertEqual(rate.enter(current: 2_500_000, showsPicture: false), LiveBackgroundBitRate.background)
    XCTAssertNil(rate.enter(current: 1, showsPicture: false))
    XCTAssertEqual(rate.leave(), 2_500_000)
    XCTAssertNil(rate.leave())
  }

  func testPictureInPictureKeepsTheVideo() {
    var rate = LiveBackgroundBitRate()
    XCTAssertNil(rate.enter(current: 0, showsPicture: true))
    XCTAssertNil(rate.leave())
  }
}
