import SwiftUI

struct DemoAudioWaveform: View {
  let isPlaying: Bool
  let playbackTime: Double
  let audioLevel: Float
  let frameDate: Date

  var body: some View {
    Canvas { context, size in
      let count = 38
      let spacing: CGFloat = 2
      let width = max(
        1,
        (size.width - CGFloat(count - 1) * spacing) / CGFloat(count)
      )
      let clock = frameDate.timeIntervalSinceReferenceDate
      let progressPhase = playbackTime * 0.42
      let measuredLevel = Double(min(1, max(0, audioLevel)))

      for index in 0..<count {
        let x = CGFloat(index) * (width + spacing)
        let seeded = sin(Double(index * 19 + 7) * 0.41) * 0.5 + 0.5
        let live = sin(clock * (2.1 + seeded) + Double(index) * 0.68)
        let signal = isPlaying
          ? 0.12 + measuredLevel * 0.42
            + abs(live) * (0.18 + measuredLevel * 0.3 + seeded * 0.12)
          : 0.14 + abs(sin(progressPhase + Double(index) * 0.5)) * 0.16
        let height = max(3, size.height * signal)
        let rect = CGRect(
          x: x,
          y: (size.height - height) / 2,
          width: width,
          height: height
        )
        context.fill(
          Path(roundedRect: rect, cornerRadius: width / 2),
          with: .color(.white.opacity(isPlaying ? 0.9 : 0.5))
        )
      }
    }
    .accessibilityHidden(true)
  }
}
