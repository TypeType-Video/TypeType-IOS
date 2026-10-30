import SwiftUI

struct LiveSettingsIconTile: View {
  let icon: String
  @Environment(\.themePalette) private var palette

  var body: some View {
    Image(systemName: icon)
      .font(.system(size: 18, weight: .regular))
      .symbolRenderingMode(.hierarchical)
      .foregroundStyle(palette.accent)
      .frame(width: 28)
      .accessibilityHidden(true)
  }
}

struct LiveSettingsLinkRow<Destination: View>: View {
  @Environment(\.themePalette) private var palette
  let title: String
  var subtitle: String? = nil
  let icon: String
  var value: String? = nil
  var badge: Int = 0
  @ViewBuilder let destination: () -> Destination

  var body: some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: 12) {
        LiveSettingsIconTile(icon: icon)
        VStack(alignment: .leading, spacing: 2) {
          Text(LocalizedStringKey(title))
            .foregroundStyle(.primary)
          if let subtitle {
            Text(LocalizedStringKey(subtitle))
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        Spacer(minLength: 0)
        if let value {
          Text(value)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        if badge > 0 {
          LiveCountBadge(count: badge)
        }
      }
    }
  }
}

struct LiveCountBadge: View {
  let count: Int
  @Environment(\.themePalette) private var palette

  var body: some View {
    Text(count, format: .number)
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
