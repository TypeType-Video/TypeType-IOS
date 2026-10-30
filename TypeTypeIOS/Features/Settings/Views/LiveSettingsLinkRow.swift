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
        RoundedRectangle(cornerRadius: 7, style: .continuous)
          .fill(color.gradient)
      }
      .overlay {
        // Glass rim: a light top edge fading out, like the iOS 26 Settings tiles.
        RoundedRectangle(cornerRadius: 7, style: .continuous)
          .strokeBorder(
            LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .bottom),
            lineWidth: 0.75
          )
      }
  }
}

/// An iOS-Settings row: icon tile, plain title, the pushed page. The list
/// draws the chevron and hairline automatically; subtitles are left out on
/// purpose: section grouping keeps the list clear instead.
struct LiveSettingsLinkRow<Destination: View>: View {
  @Environment(\.themePalette) private var palette
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
        Text(LocalizedStringKey(title))
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
                  .fill(palette.accent.opacity(0.5))
                  .glassEffect(.regular.tint(palette.accent), in: .capsule)
              } else {
                Capsule().fill(palette.accent)
              }
            }
        }
      }
    }
  }
}
