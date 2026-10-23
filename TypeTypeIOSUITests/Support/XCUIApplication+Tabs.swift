import XCTest

extension XCUIApplication {
  var usesFloatingTabItems: Bool {
    frame.width >= 600
  }

  private static let tabIdentifiers = [
    "Home": "tab.home",
    "Subscriptions": "tab.subscriptions",
    "History": "tab.history",
    "Playlists": "tab.playlists",
    "More": "tab.more",
  ]

  func tabItem(_ title: String) -> XCUIElement {
    let key = Self.tabIdentifiers[title] ?? title
    return usesFloatingTabItems
      ? buttons[key].firstMatch
      : tabBars.buttons[key]
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

  func searchField(_ prompt: String) -> XCUIElement {
    let existingField = searchFields[prompt]
    if existingField.waitForExistence(timeout: 1) {
      return existingField
    }

    let textField = textFields[prompt]
    if textField.waitForExistence(timeout: 1) {
      return textField
    }

    let searchButton = buttons["Search"]
    XCTAssertTrue(searchButton.waitForExistence(timeout: 2))
    searchButton.tap()

    if existingField.waitForExistence(timeout: 2) {
      return existingField
    }
    if textField.waitForExistence(timeout: 2) {
      return textField
    }
    let anyField = searchFields.firstMatch
    XCTAssertTrue(anyField.waitForExistence(timeout: 2))
    return anyField
  }

  func notificationControl() -> XCUIElement {
    let direct = buttons["demo.home.notifications"]
    if direct.waitForExistence(timeout: 1) {
      return direct
    }

    let navigationBar = navigationBars.firstMatch
    XCTAssertTrue(navigationBar.waitForExistence(timeout: 2))
    let overflow = navigationBar.buttons["More"]
    if overflow.waitForExistence(timeout: 1) {
      overflow.tap()
    } else {
      navigationBar.coordinate(
        withNormalizedOffset: CGVector(dx: 0.94, dy: 0.25)
      ).tap()
    }
    let bell = images["bell"].firstMatch
    XCTAssertTrue(bell.waitForExistence(timeout: 2))
    return bell
  }
}
