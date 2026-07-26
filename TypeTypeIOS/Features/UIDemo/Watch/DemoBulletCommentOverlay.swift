import SwiftUI

struct DemoBulletCommentOverlay: View {
  let preferences: DemoSessionPreferences

  var body: some View {
    GeometryReader { geometry in
      TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
        let elapsed = timeline.date.timeIntervalSinceReferenceDate
        let travel = geometry.size.width + 280
        let duration = max(3.5, 8 / preferences.bulletCommentSpeed)
        let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration
        Text("Open video, open protocol, open community")
          .font(
            .system(
              size: 12 * preferences.bulletCommentSize,
              weight: .semibold
            )
          )
          .foregroundStyle(captionColor)
          .padding(.horizontal, 9)
          .padding(.vertical, 4)
          .background(.black.opacity(preferences.captionBackgroundOpacity))
          .clipShape(Capsule())
          .fixedSize()
          .position(
            x: geometry.size.width + 140 - (travel * CGFloat(progress)),
            y: 45
          )
      }
    }
    .allowsHitTesting(false)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Bullet comment")
    .accessibilityIdentifier("demo.player.bullet-comment")
  }

  private var captionColor: Color {
    switch preferences.captionColor {
    case "Yellow": return .yellow
    case "Cyan": return .cyan
    default: return .white
    }
  }
}
