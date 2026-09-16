import XCTest

extension XCUIApplication {
  var usesFloatingTabItems: Bool {
    frame.width >= 600
  }

  func tabItem(_ title: String) -> XCUIElement {
    usesFloatingTabItems
      ? buttons[title].firstMatch
      : tabBars.buttons[title]
  }

  func tapTab(_ title: String) {
    let tab = tabItem(title)
    XCTAssertTrue(tab.waitForExistence(timeout: 3))
    if usesFloatingTabItems {
      tab.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
      ).tap()
      return
    }
    tab.tap()
  }
}
