import Foundation
import XCTest

func livePlaybackPosition(
  from element: XCUIElement
) -> TimeInterval? {
  if let number = element.value as? NSNumber {
    return number.doubleValue
  }
  guard let rawValue = element.value as? String else {
    return nil
  }
  if let value = TimeInterval(rawValue) {
    return value
  }

  for locale in [
    Locale.current,
    Locale(identifier: "fr_FR"),
    Locale(identifier: "en_US"),
  ] {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .decimal
    formatter.isLenient = true
    if let value = formatter.number(from: rawValue) {
      return value.doubleValue
    }
  }

  let ungroupedValue = rawValue
    .replacingOccurrences(of: "\u{202F}", with: "")
    .replacingOccurrences(of: "\u{00A0}", with: "")
    .replacingOccurrences(of: " ", with: "")
  if let value = TimeInterval(ungroupedValue) {
    return value
  }

  let scanner = Scanner(string: rawValue)
  scanner.locale = Locale(identifier: "en_US_POSIX")
  if let value = scanner.scanDouble() {
    return value
  }

  guard
    let range = rawValue.range(
      of: #"[-+]?\d+(?:[.,]\d+)?"#,
      options: .regularExpression
    )
  else {
    return nil
  }
  return TimeInterval(
    rawValue[range].replacingOccurrences(of: ",", with: ".")
  )
}
