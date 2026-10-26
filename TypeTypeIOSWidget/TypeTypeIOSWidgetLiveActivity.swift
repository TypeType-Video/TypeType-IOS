import ActivityKit
import SwiftUI
import WidgetKit

/// The playback Live Activity: lock-screen banner plus the Dynamic Island
/// layouts. The buttons perform the shared intents, which the app turns
/// into real player commands through `PlaybackActivityBridge`.
struct TypeTypeIOSWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(
      for: PlaybackActivityAttributes.self
    ) { context in
      LiveActivityLockScreenView(state: context.state)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 10) {
            LiveActivityThumbnail(state: context.state)
            VStack(alignment: .leading, spacing: 2) {
              Text(context.state.title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
              if !context.state.channelName.isEmpty {
                Text(context.state.channelName)
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
            }
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          Button(intent: PlaybackToggleIntent()) {
            Image(
              systemName: context.state.isPlaying
                ? "pause.fill" : "play.fill"
            )
            .font(.title3)
          }
          .buttonStyle(.plain)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack(spacing: 14) {
            Button(intent: PlaybackPreviousIntent()) {
              Image(systemName: "backward.fill")
            }
            .buttonStyle(.plain)
            LiveActivityProgress(state: context.state)
            Button(intent: PlaybackNextIntent()) {
              Image(systemName: "forward.fill")
            }
            .buttonStyle(.plain)
          }
        }
      } compactLeading: {
        Image(systemName: "waveform")
      } compactTrailing: {
        Button(intent: PlaybackToggleIntent()) {
          Image(
            systemName: context.state.isPlaying
              ? "pause.fill" : "play.fill"
          )
        }
        .buttonStyle(.plain)
      } minimal: {
        Image(systemName: "waveform")
      }
    }
  }
}

private struct LiveActivityThumbnail: View {
  let state: PlaybackActivityAttributes.ContentState

  var body: some View {
    if let reference = state.thumbnailURL,
      let url = URL(string: reference)
    {
      AsyncImage(url: url) { phase in
        if let image = phase.image {
          image.resizable().aspectRatio(contentMode: .fill)
        } else {
          Color.white.opacity(0.15)
        }
      }
      .frame(width: 52, height: 30)
      .clipShape(
        RoundedRectangle(cornerRadius: 6, style: .continuous)
      )
    } else {
      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .fill(Color.white.opacity(0.15))
        .frame(width: 52, height: 30)
        .overlay {
          Image(systemName: "waveform")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
  }
}

private struct LiveActivityProgress: View {
  let state: PlaybackActivityAttributes.ContentState

  var body: some View {
    if let duration = state.durationMilliseconds, duration > 0 {
      ProgressView(
        value: min(
          Double(state.positionMilliseconds) / Double(duration),
          1
        )
      )
      .tint(.white)
    } else {
      ProgressView()
    }
  }
}

private struct LiveActivityLockScreenView: View {
  let state: PlaybackActivityAttributes.ContentState

  var body: some View {
    HStack(spacing: 12) {
      LiveActivityThumbnail(state: state)
      VStack(alignment: .leading, spacing: 4) {
        Text(state.title)
          .font(.footnote.weight(.semibold))
          .lineLimit(1)
        if !state.channelName.isEmpty {
          Text(state.channelName)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        LiveActivityProgress(state: state)
      }
      Spacer(minLength: 8)
      Button(intent: PlaybackToggleIntent()) {
        Image(
          systemName: state.isPlaying ? "pause.fill" : "play.fill"
        )
        .font(.title2)
      }
      .buttonStyle(.plain)
    }
    .padding(14)
  }
}
