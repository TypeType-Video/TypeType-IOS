import XCTest
@testable import TypeTypeIOS

final class PictureInPictureRestoreTests: XCTestCase {
  func testRestorePreparesAndCompletesOnlyWhenExpanded() {
    var presentationWasPrepared = false
    var completionResult: Bool?

    PictureInPictureRestore.restore(
      canRestore: true,
      prepare: { presentationWasPrepared = true },
      isPrepared: { presentationWasPrepared },
      completion: { completionResult = $0 }
    )

    XCTAssertTrue(presentationWasPrepared)
    XCTAssertEqual(completionResult, true)
  }

  func testInactivePlaybackFailsRestorationWithoutPreparingUI() {
    var presentationWasPrepared = false
    var completionResult: Bool?

    PictureInPictureRestore.restore(
      canRestore: false,
      prepare: { presentationWasPrepared = true },
      isPrepared: { presentationWasPrepared },
      completion: { completionResult = $0 }
    )

    XCTAssertFalse(presentationWasPrepared)
    XCTAssertEqual(completionResult, false)
  }
}
