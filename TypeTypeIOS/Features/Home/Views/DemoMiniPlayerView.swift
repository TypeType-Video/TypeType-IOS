import SwiftUI

struct DemoMiniPlayerView: View {
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  @ObservedObject var controller: DemoPlayerController
  let onExpand: () -> Void
  let onClose: () -> Void

  var body: some View {
    HStack(spacing: 11) {
      Button(action: onExpand) {
        DemoArtworkView(video: displayVideo)
          .frame(width: 86, height: 49)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open \(displayVideo.title)")
      .accessibilityIdentifier("demo.miniplayer.open")

      Button(action: onExpand) {
        VStack(alignment: .leading, spacing: 3) {
          Text(displayVideo.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
          Text(video.channel)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)

      Button(action: controller.togglePlayback) {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .frame(width: 34, height: 40)
      }
      .accessibilityLabel(isPlaying ? "Pause" : "Play")
      .accessibilityIdentifier("demo.miniplayer.playback")

      Button(action: onClose) {
        Image(systemName: "xmark")
          .frame(width: 30, height: 40)
      }
      .accessibilityLabel("Close player")
      .accessibilityIdentifier("demo.miniplayer.close")
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      .regularMaterial,
      in: RoundedRectangle(cornerRadius: 18, style: .continuous)
    )
    .overlay(alignment: .top) {
      Rectangle()
        .fill(DemoTheme.separator)
        .frame(height: 0.5)
        .padding(.horizontal, 18)
    }
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: .black.opacity(0.22), radius: 12, y: 5)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("demo.miniplayer")
  }

  private var isPlaying: Bool {
    controller.state == .playing
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }
}
