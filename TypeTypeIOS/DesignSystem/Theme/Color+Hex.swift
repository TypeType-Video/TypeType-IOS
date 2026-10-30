import SwiftUI

extension Color {
  init?(hex: String) {
    var value = hex.trimmingCharacters(in: .whitespaces)
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let number = UInt64(value, radix: 16) else {
      return nil
    }
    self.init(
      red: Double((number >> 16) & 0xFF) / 255,
      green: Double((number >> 8) & 0xFF) / 255,
      blue: Double(number & 0xFF) / 255
    )
  }

  var hexString: String {
    let ui = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    ui.getRed(&red, green: &green, blue: &blue, alpha: nil)
    return String(
      format: "#%02X%02X%02X",
      Int(red * 255), Int(green * 255), Int(blue * 255)
    )
  }
}
