import Foundation

/// Avatar helpers shared by the profile and account surfaces.
enum LiveAvatar {
  /// Emoji avatars arrive as hex constants ("1F600", compound codes joined
  /// with "-"); returns the rendered glyph or nil for anything else.
  static func emoji(fromHexCode code: String) -> String? {
    var scalars = String.UnicodeScalarView()
    for part in code.split(separator: "-") {
      guard let value = UInt32(part, radix: 16),
        let scalar = UnicodeScalar(value)
      else { return nil }
      scalars.append(scalar)
    }
    return scalars.isEmpty ? nil : String(scalars)
  }
}
