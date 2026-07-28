import SwiftUI

struct LiveMiniPlayerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let onExpand: () -> Void

  var body: some View {
    if let video = coordinator.currentVideo,
      let controller = coordinator.controller {
      VStack(spacing: 0) {
        ProgressView(
          value: min(max(controller.position, 0), max(controller.duration, 1)),
          total: max(controller.duration, 1)
        )
        .progressViewStyle(.linear)
        .tint(DemoTheme.accent)
        .frame(height: 2)

        HStack(spacing: 11) {
          Button(action: onExpand) {
            LiveRemoteImage(url: video.thumbnail)
              .frame(width: 80, height: 45)
              .aspectRatio(16 / 9, contentMode: .fill)
              .clipped()
              .clipShape(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Open \(video.title)")
          .accessibilityIdentifier("live.miniplayer.open")

          Button(action: onExpand) {
            VStack(alignment: .leading, spacing: 3) {
              Text(video.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
              Text(video.uploaderName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .buttonStyle(.plain)

          if coordinator.sleepTimer.isActive {
            Image(systemName: "moon.zzz.fill")
              .font(.caption)
              .foregroundStyle(.tint)
              .accessibilityLabel(
                "Sleep timer \(coordinator.sleepTimer.summary)"
              )
          }

          Button(action: controller.togglePlayback) {
            Image(
              systemName: controller.state == .playing
                ? "pause.fill"
                : "play.fill"
            )
            .frame(width: 34, height: 40)
          }
          .accessibilityLabel(
            controller.state == .playing ? "Pause" : "Play"
          )
          .accessibilityIdentifier("live.miniplayer.playback")

          Button(action: coordinator.close) {
            Image(systemName: "xmark")
              .frame(width: 30, height: 40)
          }
          .accessibilityLabel("Close player")
          .accessibilityIdentifier("live.miniplayer.close")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
      }
      .frame(maxWidth: .infinity)
      .background(.regularMaterial)
      .overlay(alignment: .top) {
        Divider()
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("live.miniplayer")
    }
  }
}
