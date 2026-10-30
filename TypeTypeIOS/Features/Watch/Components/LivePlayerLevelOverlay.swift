import SwiftUI

// Same ring as the Android player: 128 pt black disc, 8 pt ring from 12 o'clock, level icon in the middle.
struct LivePlayerLevelOverlay: View {
  let kind: PlayerSwipeAdjustmentKind
  let fraction: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .fill(.black.opacity(0.62))
      Circle()
        .stroke(.white.opacity(0.24), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .padding(14)
      Circle()
        .trim(from: 0, to: min(max(fraction, 0), 1))
        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .padding(14)
      Image(systemName: icon)
        .font(.system(size: 50, weight: .regular))
        .foregroundStyle(.white)
        .frame(width: 64, height: 64)
    }
    .frame(width: 128, height: 128)
    .accessibilityHidden(true)
  }

  private var icon: String {
    switch kind {
    case .brightness:
      if fraction < 0.25 { return "sun.min.fill" }
      return fraction < 0.75 ? "sun.lefthalf.filled" : "sun.max.fill"
    case .volume:
      if fraction <= 0 { return "speaker.slash.fill" }
      if fraction < 0.25 { return "speaker.fill" }
      return fraction < 0.75 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"
    }
  }
}
