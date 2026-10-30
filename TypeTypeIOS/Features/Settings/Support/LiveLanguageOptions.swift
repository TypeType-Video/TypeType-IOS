import Foundation

enum LiveLanguageOptions {
  static let codes = [
    "en", "fr", "es", "de", "it", "pt", "ru", "ja", "ko", "zh",
    "ar", "hi", "nl", "pl", "sv", "tr", "uk", "id", "vi",
  ]

  static func nativeName(of code: String) -> String {
    let name = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
    return name.prefix(1).uppercased() + name.dropFirst()
  }

  static var options: [(String, String)] {
    [("", "Auto")] + codes.map { ($0, nativeName(of: $0)) }
  }
}
