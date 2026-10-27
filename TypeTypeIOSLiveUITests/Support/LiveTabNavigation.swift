import XCTest

/// Navigation helpers for the library/search tab arrangement. The search
/// entry rides as the last tab in the bar; the three label variants cover
/// the test device languages.
extension XCUIApplication {
  var searchTabButton: XCUIElement {
    let bar = tabBars.firstMatch
    for label in ["Search", "Suche", "Recherche"] {
      let button = bar.buttons[label]
      if button.exists {
        return button
      }
    }
    return bar.buttons.element(boundBy: max(bar.buttons.count - 1, 0))
  }

  func openSearchTab() {
    searchTabButton.tap()
  }
}
