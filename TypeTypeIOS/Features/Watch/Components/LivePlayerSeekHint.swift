import SwiftUI

// Same hint as the Android player: a dark disc bulging from the tapped edge over 40% of the width, three pulsing
// chevrons, and a label that bumps on every tap.
struct LivePlayerSeekHint: View {
  let feedback: PlayerDoubleTapSeekFeedback
  @State private var bump: CGFloat = 1

  var body: some View {
    GeometryReader { proxy in
      let forward = feedback.direction == .forward
      ZStack {
        Canvas { context, size in
          let radius = size.height * 0.9
          let centerX = forward ? radius : size.width - radius
          let disc = CGRect(x: centerX - radius, y: size.height / 2 - radius, width: radius * 2, height: radius * 2)
          context.fill(Path(ellipseIn: disc), with: .color(.black.opacity(0.34)))
        }
        VStack(spacing: 6) {
          LivePlayerSeekChevrons()
            .scaleEffect(x: forward ? 1 : -1, y: 1)
          Text(forward ? "+\(feedback.seconds) s" : "\u{2212}\(feedback.seconds) s")
            .font(.system(size: 16, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .scaleEffect(bump)
        }
      }
      .frame(width: proxy.size.width * 0.4, height: proxy.size.height)
      .clipped()
      .frame(maxWidth: .infinity, alignment: forward ? .trailing : .leading)
    }
    .onAppear(perform: bounce)
    .onChange(of: feedback.pulse) { bounce() }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func bounce() {
    bump = 1.14
    withAnimation(.interpolatingSpring(stiffness: 400, damping: 18)) { bump = 1 }
    let seconds = feedback.seconds
    let text = feedback.direction == .forward
      ? String(localized: "Forward \(seconds) seconds")
      : String(localized: "Back \(seconds) seconds")
    AccessibilityNotification.Announcement(text).post()
  }
}

private struct LivePlayerSeekChevrons: View {
  var body: some View {
    TimelineView(.animation) { timeline in
      let cycle = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.72) / 0.72
      Canvas { context, size in
        let step = size.width / 3
        let height = size.height
        let width = height * 0.8
        for index in 0..<3 {
          let phase = ((cycle - Double(index) / 3).truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
          let glow = 1 - abs(phase * 2 - 1)
          let left = CGFloat(index) * step + (step - width) / 2
          var chevron = Path()
          chevron.move(to: CGPoint(x: left, y: 0))
          chevron.addLine(to: CGPoint(x: left + width, y: height / 2))
          chevron.addLine(to: CGPoint(x: left, y: height))
          chevron.closeSubpath()
          context.fill(chevron, with: .color(.white.opacity(0.25 + 0.75 * glow)))
        }
      }
    }
    .frame(width: 54, height: 18)
  }
}
