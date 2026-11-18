import SwiftUI

enum LiveTwitchChatText {
  static func modes(_ room: LiveTwitchRoomState) -> [String] {
    var labels: [String] = []
    if room.subsOnly { labels.append(String(localized: "Subscribers only")) }
    if room.followersOnly == 0 {
      labels.append(String(localized: "Followers only"))
    } else if room.followersOnly > 0 {
      labels.append(String(localized: "Followers for \(Duration.seconds(room.followersOnly * 60).formatted(.units(width: .narrow)))"))
    }
    if room.slow > 0 { labels.append(String(localized: "Slow mode \(room.slow) s")) }
    if room.emoteOnly { labels.append(String(localized: "Emotes only")) }
    if room.uniqueChat { labels.append(String(localized: "Unique messages")) }
    return labels
  }

  static func percent(_ choice: LiveTwitchPollChoice, in poll: LiveTwitchPoll) -> Int {
    let total = poll.choices.reduce(0) { $0 + $1.votes }
    return total > 0 ? Int((Double(choice.votes) / Double(total) * 100).rounded()) : 0
  }

  static func subscription(_ subscription: LiveTwitchSubscription) -> String {
    switch subscription.months {
    case 2...: String(localized: "Subscribed · \(subscription.months) months")
    case 1: String(localized: "Subscribed · 1 month")
    default: String(localized: "Subscribed")
    }
  }

  static func subscriptionDetails(_ subscription: LiveTwitchSubscription) -> [String] {
    var details: [String] = []
    if subscription.streak > 1 { details.append(String(localized: "\(subscription.streak)-month streak")) }
    if subscription.prime {
      details.append("Prime")
    } else if let tier = Int(subscription.tier), tier >= 1000, tier % 1000 == 0 {
      details.append(String(localized: "Tier \(tier / 1000)"))
    }
    return details
  }

  static let defaultColors: [UInt32] = [
    0xFF0000, 0x0000FF, 0x008000, 0xB22222, 0xFF7F50, 0x9ACD32, 0xFF4500, 0x2E8B57,
    0xDAA520, 0xD2691E, 0x5F9EA0, 0x1E90FF, 0xFF69B4, 0x8A2BE2, 0x00FF7F,
  ]

  static func nameColor(_ hex: String?, login: String, dark: Bool) -> Color {
    let (red, green, blue) = nameRGB(hex, login: login, dark: dark)
    return Color(red: red / 255, green: green / 255, blue: blue / 255)
  }

  // Lifts names too dark for a dark background and darkens names too light for a light one, with the web's thresholds.
  static func nameRGB(_ hex: String?, login: String, dark: Bool) -> (Double, Double, Double) {
    let value = rgb(hex) ?? defaultColors[hash(login) % defaultColors.count]
    let channels = [Double((value >> 16) & 0xFF), Double((value >> 8) & 0xFF), Double(value & 0xFF)]
    let lum = luminance(channels)
    let (target, amount): (Double, Double) = if dark, lum < 0.18 {
      (255, min(0.75, (0.18 - lum) * 4 + 0.25))
    } else if !dark, lum > 0.45 {
      (0, min(0.6, (lum - 0.45) * 2 + 0.2))
    } else {
      (0, 0)
    }
    let mixed = channels.map { ($0 + (target - $0) * amount).rounded() }
    return (mixed[0], mixed[1], mixed[2])
  }

  private static func rgb(_ hex: String?) -> UInt32? {
    guard var hex, !hex.isEmpty else { return nil }
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard hex.count == 6 else { return nil }
    return UInt32(hex, radix: 16)
  }

  private static func hash(_ text: String) -> Int {
    var value: Int32 = 0
    for scalar in text.unicodeScalars { value = value &* 31 &+ Int32(bitPattern: scalar.value) }
    return Int(abs(Int64(value)))
  }

  private static func luminance(_ channels: [Double]) -> Double {
    let linear = channels.map { value -> Double in
      let c = value / 255
      return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
  }
}
