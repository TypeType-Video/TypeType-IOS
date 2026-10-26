import SwiftUI
import UIKit

/// SwiftUI ships no `Color.systemRed`; the Settings tiles use the iOS
/// Settings palette, so bridge UIKit's adaptive system colours across.
/// They follow light/dark automatically like every other system colour.
extension Color {
  static let systemBlue = Color(uiColor: .systemBlue)
  static let systemRed = Color(uiColor: .systemRed)
  static let systemPurple = Color(uiColor: .systemPurple)
  static let systemOrange = Color(uiColor: .systemOrange)
  static let systemGreen = Color(uiColor: .systemGreen)
  static let systemTeal = Color(uiColor: .systemTeal)
  static let systemGray = Color(uiColor: .systemGray)
}
