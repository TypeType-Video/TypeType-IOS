import AVKit
import SwiftUI

struct LiveOfflinePlaybackView: View {
  let item: LiveOfflinePlaybackItem
  @StateObject private var controller: LiveOfflinePlaybackController
  @Environment(\.dismiss) private var dismiss

  init(item: LiveOfflinePlaybackItem) {
    self.item = item
    _controller = StateObject(
      wrappedValue: LiveOfflinePlaybackController(
        fileURL: item.fileURL
      )
    )
  }

  var body: some View {
    NavigationStack {
      Group {
        if item.isAudioOnly {
          audioPlayer
        } else {
          videoPlayer
        }
      }
      .navigationTitle(item.isAudioOnly ? "Offline audio" : "Offline video")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
        }
      }
    }
    .task {
      controller.start()
    }
    .onDisappear {
      controller.stop()
    }
    .accessibilityIdentifier("live.offline-player")
  }

  private var videoPlayer: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      LiveOfflineAVPlayerView(player: controller.player)
        .ignoresSafeArea(edges: .bottom)

      if let errorMessage = controller.errorMessage {
        playbackError(errorMessage)
      }
    }
  }

  private var audioPlayer: some View {
    ZStack {
      LinearGradient(
        colors: [
          DemoTheme.accent.opacity(0.28),
          Color(uiColor: .systemBackground),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 28) {
        ZStack {
          RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.15), radius: 22, y: 12)
          Image("TypeTypeLogo")
            .resizable()
            .scaledToFit()
            .padding(42)
        }
        .frame(maxWidth: 310)
        .aspectRatio(1, contentMode: .fit)

        VStack(spacing: 6) {
          Text(item.record.title)
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)
            .lineLimit(3)
          Label("Downloaded audio", systemImage: "arrow.down.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        VStack(spacing: 8) {
          Slider(
            value: Binding(
              get: { controller.position },
              set: controller.seek(to:)
            ),
            in: 0...max(controller.duration, 1)
          )
          HStack {
            Text(Self.time(controller.position))
            Spacer()
            Text(
              "-\(Self.time(max(controller.duration - controller.position, 0)))"
            )
          }
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
        }

        HStack(spacing: 42) {
          Button {
            controller.skip(by: -15)
          } label: {
            Image(systemName: "gobackward.15")
          }
          Button(action: controller.togglePlayback) {
            Image(
              systemName: controller.isPlaying
                ? "pause.circle.fill"
                : "play.circle.fill"
            )
              .font(.system(size: 68))
          }
          Button {
            controller.skip(by: 30)
          } label: {
            Image(systemName: "goforward.30")
          }
        }
        .font(.title)
        .buttonStyle(.plain)
        .foregroundStyle(DemoTheme.accent)

        if let errorMessage = controller.errorMessage {
          Text(errorMessage)
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }
      }
      .padding(24)
    }
    .accessibilityIdentifier("live.offline-audio-player")
  }

  private func playbackError(_ message: String) -> some View {
    ContentUnavailableView(
      "Playback unavailable",
      systemImage: "exclamationmark.triangle",
      description: Text(message)
    ).liveThemedEmptyState()
      .foregroundStyle(.white)
      .padding()
      .background(.black.opacity(0.82), in: .rect(cornerRadius: 18))
      .padding()
  }

  private static func time(_ value: TimeInterval) -> String {
    guard value.isFinite else { return "0:00" }
    let total = max(Int(value.rounded(.down)), 0)
    let hours = total / 3_600
    let minutes = (total % 3_600) / 60
    let seconds = total % 60
    return hours > 0
      ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
      : String(format: "%d:%02d", minutes, seconds)
  }
}
