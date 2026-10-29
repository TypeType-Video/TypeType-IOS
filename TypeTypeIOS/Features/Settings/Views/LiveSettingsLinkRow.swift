import SwiftUI

/// An iOS-Settings icon tile: a coloured rounded square with a white glyph.
struct LiveSettingsIconTile: View {
  let icon: String
  let color: Color

  var body: some View {
    Image(systemName: icon)
      .font(.system(size: 14, weight: .semibold))
      .foregroundStyle(.white)
      .frame(width: 29, height: 29)
      .background {
        if #available(iOS 26.0, *) {
          // Tinted Liquid Glass chip: the modern Settings look.
          RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(color.opacity(0.45))
            .glassEffect(.regular.tint(color), in: .rect(cornerRadius: 7))
        } else {
          RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(color)
        }
      }
  }
}

/// An iOS-Settings row: icon tile, plain title, the pushed page. The list
/// draws the chevron and hairline automatically; subtitles are left out on
/// purpose — section grouping keeps the list clear instead.
struct LiveSettingsLinkRow<Destination: View>: View {
  let title: String
  let icon: String
  let iconColor: Color
  var value: String? = nil
  var badge: Int = 0
  @ViewBuilder let destination: () -> Destination

  var body: some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: 14) {
        LiveSettingsIconTile(icon: icon, color: iconColor)
        Text(title)
          .foregroundStyle(.primary)
        Spacer(minLength: 0)
        if let value {
          Text(value)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        if badge > 0 {
          Text(String(badge))
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
              if #available(iOS 26.0, *) {
                Capsule()
                  .fill(DemoTheme.accent.opacity(0.5))
                  .glassEffect(.regular.tint(DemoTheme.accent), in: .capsule)
              } else {
                Capsule().fill(DemoTheme.accent)
              }
            }
        }
      }
    }
  }
}
