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
}
