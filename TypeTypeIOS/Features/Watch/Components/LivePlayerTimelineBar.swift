import SwiftUI

struct LivePlayerTimelineBar<Marks: View>: View {
  let position: TimeInterval
  let duration: TimeInterval
  let icon: LiveSeekbarIcon
  let isScrubbing: Bool
  let onScrub: (TimeInterval) -> Void
  let onScrubEnded: (TimeInterval) -> Void
  @ViewBuilder let marks: () -> Marks

  static var height: CGFloat { 34 }

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let thumb = LiveSeekbarThumb.size(for: icon, isScrubbing: isScrubbing)
      let progressX = width * fraction
      ZStack(alignment: .leading) {
        Capsule()
          .fill(.white.opacity(0.3))
          .frame(height: trackHeight)
        Capsule()
          .fill(.white)
          .frame(width: progressX, height: trackHeight)
        marks()
          .frame(width: width, height: proxy.size.height)
        LiveSeekbarThumb(icon: icon, isScrubbing: isScrubbing)
          .offset(x: min(max(progressX - thumb / 2, 0), max(width - thumb, 0)))
      }
      .frame(width: width, height: proxy.size.height)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { onScrub(target(at: $0.location.x, width: width)) }
          .onEnded { onScrubEnded(target(at: $0.location.x, width: width)) }
      )
    }
    .frame(height: Self.height)
    .animation(.easeOut(duration: 0.12), value: isScrubbing)
    .accessibilityElement()
    .accessibilityLabel("Playback position")
    .accessibilityValue(
      String(
        localized: "\(LivePlaybackChapterNavigator.clockText(seconds: Int(position))) of \(LivePlaybackChapterNavigator.clockText(seconds: Int(duration)))"
      )
    )
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: onScrubEnded(min(position + 10, duration))
      case .decrement: onScrubEnded(max(position - 10, 0))
      @unknown default: break
      }
    }
  }

  private var fraction: CGFloat {
    guard duration > 0 else { return 0 }
    return CGFloat(min(max(position / duration, 0), 1))
  }

  private var trackHeight: CGFloat { isScrubbing ? 6 : 4 }

  private func target(at x: CGFloat, width: CGFloat) -> TimeInterval {
    guard width > 0, duration > 0 else { return 0 }
    return duration * TimeInterval(min(max(x / width, 0), 1))
  }
}
