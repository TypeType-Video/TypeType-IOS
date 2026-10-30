import SwiftUI

struct LiveAppearancePreview: View {
  @Environment(\.themePalette) private var palette
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      videoCard
        .padding(14)
      Spacer(minLength: 0)
      tabBar
    }
    .frame(height: 252)
    .background(palette.background)
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 26, style: .continuous)
        .strokeBorder(palette.separator, lineWidth: 1)
    }
    .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: palette)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("Preview of the selected appearance"))
    .accessibilityIdentifier("live.settings.appearance.preview")
  }

  private var videoCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      ZStack(alignment: .bottomLeading) {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(
            LinearGradient(
              colors: [palette.accent.opacity(0.85), palette.accent.opacity(0.35)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay {
            Image(systemName: "play.fill")
              .font(.title2)
              .foregroundStyle(.white.opacity(0.9))
          }
        ProgressView(value: 0.42)
          .tint(palette.accent)
          .padding(10)
      }
      .frame(height: 112)

      HStack(alignment: .top, spacing: 10) {
        Circle()
          .fill(palette.elevatedSurface)
          .frame(width: 30, height: 30)
        VStack(alignment: .leading, spacing: 3) {
          Text("A calm evening by the lake")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(palette.textPrimary)
            .lineLimit(1)
          Text("TypeType · 12K views")
            .font(.caption)
            .foregroundStyle(palette.textSecondary)
            .lineLimit(1)
        }
      }
    }
    .padding(10)
    .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var tabBar: some View {
    HStack {
      ForEach(Array(Self.tabs.enumerated()), id: \.offset) { index, symbol in
        Image(systemName: symbol)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(index == 0 ? palette.accent : palette.textSecondary)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, 12)
    .background(palette.elevatedSurface)
  }

  private static let tabs = ["house.fill", "rectangle.stack", "clock", "ellipsis.circle"]
}
