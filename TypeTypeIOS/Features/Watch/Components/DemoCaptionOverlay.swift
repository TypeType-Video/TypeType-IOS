import SwiftUI

struct DemoCaptionOverlay: View {
  let preferences: DemoSessionPreferences

  var body: some View {
    Text(captionText)
      .font(captionFont)
      .foregroundStyle(captionColor)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.black.opacity(preferences.captionBackgroundOpacity))
      .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .padding(.horizontal, 44)
      .padding(.bottom, 12)
      .allowsHitTesting(false)
      .accessibilityIdentifier("demo.player.caption")
  }

  private var captionText: String {
    switch preferences.subtitleLanguage {
    case "French":
      return "Vidéo ouverte, protocole ouvert, communauté ouverte"
    case "German":
      return "Offenes Video, offenes Protokoll, offene Gemeinschaft"
    default:
      return "Open video, open protocol, open community"
    }
  }

  private var captionFont: Font {
    let size: CGFloat
    switch preferences.captionSize {
    case "Small": size = 13
    case "Large": size = 20
    case "Extra large": size = 24
    default: size = 16
    }
    switch preferences.captionFont {
    case "Rounded": return .system(size: size, design: .rounded)
    case "Monospaced": return .system(size: size, design: .monospaced)
    default: return .system(size: size)
    }
  }

  private var captionColor: Color {
    switch preferences.captionColor {
    case "Yellow": return .yellow
    case "Cyan": return .cyan
    default: return .white
    }
  }
}
