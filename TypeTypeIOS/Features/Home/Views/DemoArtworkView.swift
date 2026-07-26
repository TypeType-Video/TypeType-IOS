import SwiftUI

struct DemoArtworkView: View {
  let video: DemoVideo
  var showsDuration = true

  var body: some View {
    ZStack {
      LinearGradient(
        colors: gradientColors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Circle()
        .fill(Color.white.opacity(0.08))
        .frame(width: 210, height: 210)
        .offset(x: 95, y: -55)

      Image(video.artwork.rawValue)
        .resizable()
        .interpolation(.none)
        .scaledToFit()
        .padding(artworkPadding)
        .shadow(color: .black.opacity(0.24), radius: 12, y: 8)

      LinearGradient(
        colors: [.clear, .black.opacity(0.36)],
        startPoint: .center,
        endPoint: .bottom
      )
    }
    .aspectRatio(16 / 9, contentMode: .fit)
    .overlay(alignment: .bottomTrailing) {
      if showsDuration {
        durationBadge
          .padding(6)
      }
    }
    .clipped()
  }

  private var durationBadge: some View {
    Text(video.duration)
      .font(.caption2.monospacedDigit().weight(.semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(.black.opacity(0.82))
      .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
      .accessibilityLabel("Duration \(video.duration)")
  }

  private var artworkPadding: CGFloat {
    video.artwork == .typeType ? 54 : 26
  }

  private var gradientColors: [Color] {
    switch video.artwork {
    case .television:
      return [Color(red: 0.18, green: 0.22, blue: 0.48), .indigo]
    case .dog:
      return [.orange, Color(red: 0.62, green: 0.16, blue: 0.18)]
    case .cat:
      return [Color(red: 0.55, green: 0.16, blue: 0.42), .purple]
    case .bird:
      return [.cyan, Color(red: 0.05, green: 0.34, blue: 0.64)]
    case .pipePipe:
      return [Color(red: 0.08, green: 0.22, blue: 0.32), .black]
    case .typeType:
      return [Color(red: 0.35, green: 0.09, blue: 0.13), .black]
    }
  }
}
