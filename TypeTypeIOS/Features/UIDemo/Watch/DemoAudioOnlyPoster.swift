import SwiftUI

struct DemoAudioOnlyPoster: View {
  @ObservedObject var controller: DemoPlayerController
  let video: DemoVideo

  var body: some View {
    TimelineView(
      .animation(
        minimumInterval: 1.0 / 60.0,
        paused: controller.state != .playing
      )
    ) { timeline in
      poster(at: currentTime, frameDate: timeline.date)
    }
  }

  private func poster(
    at playbackTime: Double,
    frameDate: Date
  ) -> some View {
    ZStack {
      ambientArtwork
      LinearGradient(
        colors: [.black.opacity(0.12), .black.opacity(0.82)],
        startPoint: .top,
        endPoint: .bottom
      )
      DemoAudioWaveform(
        isPlaying: controller.state == .playing,
        playbackTime: playbackTime,
        audioLevel: controller.audioLevel,
        frameDate: frameDate
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .opacity(0.42)
      .blendMode(.screen)
      .mask {
        LinearGradient(
          colors: [.clear, .white, .white, .clear],
          startPoint: .top,
          endPoint: .bottom
        )
      }

      HStack(spacing: 14) {
        DemoArtworkView(video: video)
          .frame(width: 84, height: 84)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          .shadow(color: .black.opacity(0.32), radius: 18, y: 8)
          .accessibilityIdentifier("demo.player.audio-only.artwork")

        DemoMarqueeText(
          text: video.title,
          font: .subheadline.weight(.semibold),
          color: .white
        )
        .frame(maxWidth: .infinity)
        .frame(height: 22)
        .accessibilityIdentifier("demo.player.audio-only.title")
      }
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      Color.clear
        .frame(width: 1, height: 1)
        .accessibilityElement()
        .accessibilityLabel("Audio-only player")
        .accessibilityIdentifier("demo.player.audio-only")
        .allowsHitTesting(false)
    }
    .foregroundStyle(.white)
    .clipped()
  }

  private var ambientArtwork: some View {
    DemoArtworkView(video: video)
      .scaleEffect(1.65)
      .blur(radius: 30)
      .saturation(1.35)
      .overlay(paletteColor.opacity(0.26))
  }

  private var currentTime: Double {
    let value = controller.player.currentTime().seconds
    return value.isFinite ? max(0, value) : 0
  }

  private var paletteColor: Color {
    switch video.artwork {
    case .television: .indigo
    case .dog: .orange
    case .cat: .purple
    case .bird: .cyan
    case .pipePipe: Color(red: 0.05, green: 0.38, blue: 0.48)
    case .typeType: Color(red: 0.82, green: 0.16, blue: 0.22)
    }
  }

}
