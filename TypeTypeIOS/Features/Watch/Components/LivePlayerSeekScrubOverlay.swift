import SwiftUI

// Same scrub chrome as the Android player: storyboard frame and time above an emphasized track.
struct LivePlayerSeekScrubOverlay: View {
  @Environment(\.themePalette) private var palette
  let position: TimeInterval
  let isFine: Bool
  let duration: TimeInterval
  let storyboard: LivePlaybackPreviewFrames?
  let windows: [LiveSponsorBlockWindow]
  let isFullscreen: Bool

  var body: some View {
    VStack(spacing: 0) {
      LivePlayerSeekPreview(position: position, isFine: isFine, storyboard: storyboard)
      track
        .frame(height: isFullscreen ? 52 : 40)
        .padding(.leading, isFullscreen ? 12 : 4)
        .padding(.trailing, isFullscreen ? 8 : 4)
        .padding(.bottom, isFullscreen ? 6 : 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private var track: some View {
    Canvas { context, size in
      let height: CGFloat = 6
      let thumb: CGFloat = 22
      let top = (size.height - height) / 2
      let span = max(duration, 1)
      let progressX = min(max(position / span, 0), 1) * size.width
      let bar = { (x: CGFloat, width: CGFloat) in
        Path(roundedRect: CGRect(x: x, y: top, width: width, height: height), cornerRadius: height / 2)
      }
      context.fill(bar(0, size.width), with: .color(.black.opacity(0.38)))
      context.fill(bar(0, progressX), with: .color(palette.accent))
      for window in windows {
        let start = min(max(window.start / span, 0), 1) * size.width
        let end = min(max(window.end / span, 0), 1) * size.width
        context.fill(bar(start, max(end - start, 3)), with: .color(LiveSponsorBlockPalette.color(for: window.segment.category)))
      }
      let thumbX = min(max(progressX - thumb / 2, 0), max(size.width - thumb, 0))
      context.fill(Path(ellipseIn: CGRect(x: thumbX, y: (size.height - thumb) / 2, width: thumb, height: thumb)), with: .color(.white))
    }
  }
}

enum LiveSponsorBlockPalette {
  static func color(for category: String) -> Color {
    switch category {
    case "sponsor": .systemOrange
    case "selfpromo": .systemBlue
    case "interaction": .systemPurple
    case "intro", "outro": .systemGreen
    case "music", "music_offtopic": .systemRed
    default: .systemGray
    }
  }
}
