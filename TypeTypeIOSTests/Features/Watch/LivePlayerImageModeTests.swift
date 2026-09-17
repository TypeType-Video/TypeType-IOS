import AVKit
import XCTest
import QuartzCore
@testable import TypeTypeIOS

final class LivePlayerImageModeTests: XCTestCase {
  func testModesMatchAndroidOptionsAndAVKitGravity() {
    XCTAssertEqual(
      LivePlayerImageMode.allCases.map(\.rawValue),
      ["fit", "crop", "stretch"]
    )
    XCTAssertEqual(LivePlayerImageMode.fit.videoGravity, .resizeAspect)
    XCTAssertEqual(LivePlayerImageMode.crop.videoGravity, .resizeAspectFill)
    XCTAssertEqual(LivePlayerImageMode.stretch.videoGravity, .resize)
  }
}
