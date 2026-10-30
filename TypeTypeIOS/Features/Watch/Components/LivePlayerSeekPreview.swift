import SwiftUI

struct LivePlayerSeekPreview: View {
  static let width: CGFloat = 160
  @Environment(\.themePalette) private var palette
  let position: TimeInterval
  var isFine = false
  let storyboard: LivePlaybackPreviewFrames?

  var body: some View {
    VStack(spacing: 4) {
      if let frame = storyboard?.frame(at: position) {
        storyboardFrame(frame)
      }
      Text(timecode)
        .font(.caption2.weight(.medium).monospacedDigit())
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(palette.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .frame(width: Self.width)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private var timecode: String {
    let time = LivePlaybackChapterNavigator.clockText(seconds: Int(position))
    return isFine ? String(localized: "Fine seeking · \(time)") : time
  }

  private func storyboardFrame(_ frame: LivePlaybackStoryboardFrame) -> some View {
    let scale = Self.width / CGFloat(frame.frameWidth)
    return LiveRemoteImage(url: frame.url)
      .frame(
        width: CGFloat(frame.frameWidth * frame.columns) * scale,
        height: CGFloat(frame.frameHeight * frame.rows) * scale
      )
      .offset(
        x: -CGFloat(frame.column * frame.frameWidth) * scale,
        y: -CGFloat(frame.row * frame.frameHeight) * scale
      )
      .frame(width: Self.width, height: 90, alignment: .topLeading)
      .clipped()
      .padding(3)
      .background(palette.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}
