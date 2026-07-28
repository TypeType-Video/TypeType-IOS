import AVFoundation
import CoreMedia
import Foundation

enum LiveCaptionTextStyleRuleBuilder {
  static func rules(
    for styles: LiveCaptionStyles
  ) -> [AVTextStyleRule]? {
    let attributes = attributes(for: styles)
    guard !attributes.isEmpty,
      let rule = AVTextStyleRule(
        textMarkupAttributes: attributes
      )
    else {
      return nil
    }
    return [rule]
  }

  static func attributes(
    for styles: LiveCaptionStyles
  ) -> [String: Any] {
    var attributes: [String: Any] = [:]
    if let color = color(
      styles.textColor,
      opacity: styles.textOpacity
    ) {
      attributes[key(kCMTextMarkupAttribute_ForegroundColorARGB)] = color
    }
    if let color = color(
      styles.textBackground,
      opacity: styles.textBackgroundOpacity
    ) {
      attributes[
        key(kCMTextMarkupAttribute_CharacterBackgroundColorARGB)
      ] = color
    }
    if let color = color(
      styles.displayBackground,
      opacity: styles.displayBackgroundOpacity
    ) {
      attributes[key(kCMTextMarkupAttribute_BackgroundColorARGB)] = color
    }
    if let size = percentage(styles.fontSize) {
      attributes[key(kCMTextMarkupAttribute_RelativeFontSize)] = size
    }
    applyFont(styles.fontFamily, to: &attributes)
    if let edge = edgeStyle(styles.textShadow) {
      attributes[key(kCMTextMarkupAttribute_CharacterEdgeStyle)] = edge
    }
    return attributes
  }

  private static func applyFont(
    _ value: String,
    to attributes: inout [String: Any]
  ) {
    let normalized = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !normalized.isEmpty else { return }
    let generic = genericFont(normalized)
    if let generic {
      attributes[key(kCMTextMarkupAttribute_GenericFontFamilyName)] =
        generic
    } else {
      attributes[key(kCMTextMarkupAttribute_FontFamilyName)] = normalized
    }
  }

  private static func genericFont(_ value: String) -> String? {
    switch normalized(value) {
    case "default", "system":
      return key(kCMTextMarkupGenericFontName_Default)
    case "serif", "proserif", "proportionalserif":
      return key(kCMTextMarkupGenericFontName_ProportionalSerif)
    case "sansserif", "prosans", "proportionalsansserif":
      return key(kCMTextMarkupGenericFontName_ProportionalSansSerif)
    case "monospace", "mono":
      return key(kCMTextMarkupGenericFontName_Monospace)
    case "monoserif", "monospaceserif":
      return key(kCMTextMarkupGenericFontName_MonospaceSerif)
    case "monosans", "monospacesansserif":
      return key(kCMTextMarkupGenericFontName_MonospaceSansSerif)
    case "casual":
      return key(kCMTextMarkupGenericFontName_Casual)
    case "cursive":
      return key(kCMTextMarkupGenericFontName_Cursive)
    case "capitals", "smallcapital", "smallcapitals":
      return key(kCMTextMarkupGenericFontName_SmallCapital)
    default:
      return nil
    }
  }

  private static func edgeStyle(_ value: String) -> String? {
    switch normalized(value) {
    case "none":
      return key(kCMTextMarkupCharacterEdgeStyle_None)
    case "dropshadow":
      return key(kCMTextMarkupCharacterEdgeStyle_DropShadow)
    case "raised":
      return key(kCMTextMarkupCharacterEdgeStyle_Raised)
    case "depressed":
      return key(kCMTextMarkupCharacterEdgeStyle_Depressed)
    case "outline", "uniform":
      return key(kCMTextMarkupCharacterEdgeStyle_Uniform)
    default:
      return nil
    }
  }

  private static func color(
    _ value: String,
    opacity: String
  ) -> [NSNumber]? {
    let trimmed = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !trimmed.isEmpty else { return nil }
    let hex = trimmed.hasPrefix("#")
      ? String(trimmed.dropFirst())
      : trimmed
    let expanded: String
    if hex.count == 3 {
      expanded = hex.map { "\($0)\($0)" }.joined()
    } else {
      expanded = hex
    }
    guard expanded.count == 6,
      let value = UInt64(expanded, radix: 16)
    else {
      return nil
    }
    let alpha = min(max((percentage(opacity) ?? 100) / 100, 0), 1)
    return [
      NSNumber(value: alpha),
      NSNumber(value: Double((value >> 16) & 0xff) / 255),
      NSNumber(value: Double((value >> 8) & 0xff) / 255),
      NSNumber(value: Double(value & 0xff) / 255),
    ]
  }

  private static func percentage(_ value: String) -> Double? {
    let trimmed = value.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !trimmed.isEmpty else { return nil }
    return Double(trimmed.replacingOccurrences(of: "%", with: ""))
  }

  private static func normalized(_ value: String) -> String {
    value.lowercased().filter(\.isLetter)
  }

  private static func key(_ value: CFString) -> String {
    value as String
  }
}
