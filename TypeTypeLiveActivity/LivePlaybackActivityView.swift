import ActivityKit
import SwiftUI
import WidgetKit

/// The audio-only playback Live Activity: banner on the lock screen and the
/// Dynamic Island while a video plays in the background.
struct LivePlaybackActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LivePlaybackActivityAttributes.self) { context in
      LivePlaybackBannerView(context: context)
        .activityBackgroundTint(Color.black.opacity(0.82))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
              if context.state.isLive {
                LivePlaybackLiveBadge()
              }
              Text(context.state.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            }
            Text(context.state.channel)
              .font(.caption2)
              .foregroundStyle(.white.opacity(0.7))
              .lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          LivePlaybackPlayGlyph(isPlaying: context.state.isPlaying)
            .foregroundStyle(.white)
        }
        DynamicIslandExpandedRegion(.bottom) {
          LivePlaybackProgressLine(progress: context.state.progress)
        }
      } compactLeading: {
        LivePlaybackPlayGlyph(isPlaying: context.state.isPlaying)
          .foregroundStyle(.white)
      } compactTrailing: {
        LivePlaybackProgressRing(progress: context.state.progress)
          .foregroundStyle(.white)
      } minimal: {
        LivePlaybackPlayGlyph(isPlaying: context.state.isPlaying)
          .foregroundStyle(.white)
      }
      .keylineTint(.white)
    }
  }
}

/// Lock screen / banner presentation.
private struct LivePlaybackBannerView: View {
  let context: ActivityViewContext<LivePlaybackActivityAttributes>

  var body: some View {
    HStack(spacing: 12) {
      LivePlaybackPlayGlyph(isPlaying: context.state.isPlaying)
        .foregroundStyle(.white)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          if context.state.isLive {
            LivePlaybackLiveBadge()
          }
          Text(context.state.title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
        }
        Text(context.state.channel)
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.7))
          .lineLimit(1)
        LivePlaybackProgressLine(progress: context.state.progress)
          .padding(.top, 2)
      }
    }
    .padding(14)
  }
}

private struct LivePlaybackPlayGlyph: View {
  let isPlaying: Bool

  var body: some View {
    Image(systemName: isPlaying ? "play.fill" : "pause.fill")
      .font(.system(size: 13, weight: .bold))
  }
}

private struct LivePlaybackLiveBadge: View {
  var body: some View {
    Text("LIVE")
      .font(.system(size: 9, weight: .heavy))
      .foregroundStyle(.white)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(.red, in: Capsule())
  }
}

private struct LivePlaybackProgressRing: View {
  let progress: Double

  var body: some View {
    ZStack {
      Circle()
        .stroke(.white.opacity(0.25), lineWidth: 2)
      Circle()
        .trim(from: 0, to: max(0.02, min(1, progress)))
        .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .frame(width: 16, height: 16)
  }
}

private struct LivePlaybackProgressLine: View {
  let progress: Double

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(.white.opacity(0.25))
        Capsule()
          .fill(.white)
          .frame(width: proxy.size.width * max(0.01, min(1, progress)))
      }
    }
    .frame(height: 3)
  }
}
