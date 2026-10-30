import Foundation

enum LiveAvatar {
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
