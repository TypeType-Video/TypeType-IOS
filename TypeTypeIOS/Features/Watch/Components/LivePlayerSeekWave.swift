import SwiftUI

// Same tap wave as the Android player: three arcs widening from the tapped side over 650 ms, then "+10s".
struct LivePlayerSeekWave: View {
  let feedback: PlayerDoubleTapSeekFeedback
  @State private var start = Date()

  var body: some View {
    GeometryReader { proxy in
      let forward = feedback.direction == .forward
      ZStack(alignment: forward ? .trailing : .leading) {
        TimelineView(.animation) { timeline in
          let progress = min(timeline.date.timeIntervalSince(start) / 0.65, 1)
          Canvas { context, size in
            let origin = CGPoint(x: size.width * (forward ? 0.3 : 0.7), y: size.height / 2)
            for index in 0..<3 {
              let phase = min(max(progress - Double(index) * 0.18, 0), 1)
              guard phase > 0, phase < 1 else { continue }
              let radius = min(size.width, size.height) * (0.08 + phase * 0.5)
              let startAngle = Angle.degrees(forward ? -55 : 125)
              var arc = Path()
              arc.addArc(center: origin, radius: radius, startAngle: startAngle,
                         endAngle: startAngle + .degrees(110), clockwise: false)
              context.stroke(arc, with: .color(.white.opacity((1 - phase) * 0.9)),
                             style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
          }
          .frame(width: proxy.size.width * 0.48)
        }
        Text(forward ? "+\(feedback.seconds)s" : "-\(feedback.seconds)s")
          .font(.system(size: 24))
          .foregroundStyle(.white)
          .padding(.horizontal, 56)
      }
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: forward ? .trailing : .leading)
    }
    .onChange(of: feedback.pulse) { start = Date() }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
