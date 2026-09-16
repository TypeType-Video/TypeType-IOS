import XCTest

extension XCUIApplication {
  var usesFloatingTabItems: Bool {
    frame.width >= 600
  }

  func tabItem(_ title: String) -> XCUIElement {
    usesFloatingTabItems
      ? cells[title].firstMatch
      : tabBars.buttons[title]
  }

  func tapTab(_ title: String) {
    let tab = tabItem(title)
    XCTAssertTrue(tab.waitForExistence(timeout: 3))
    tab.tap()
  }
}
