import AVKit
import SwiftUI

struct DemoWatchPlayerView: View {
  @EnvironmentObject var session: DemoSessionStore
  @ObservedObject var controller: DemoPlayerController
  let video: DemoVideo
  @Binding var audioOnly: Bool
  let autoplayTarget: DemoVideo?
  let autoplaySeconds: Int
  let onAutoplayPlay: () -> Void
  let onAutoplayCancel: () -> Void
  @State private var presentsPlayerOptions = false
  @State private var optionsOpenedDuringPlayback = false

  var body: some View {
    playerSurface
      .aspectRatio(16 / 9, contentMode: .fit)
      .sheet(isPresented: $presentsPlayerOptions) {
        DemoPlayerOptionsSheet(
          controller: controller,
          audioOnly: $audioOnly
        )
        .onAppear {
          if optionsOpenedDuringPlayback {
            controller.player.play()
          }
        }
      }
  }

  private var playerSurface: some View {
    ZStack {
      Color.black

      if audioOnly {
        DemoAudioOnlyPoster(controller: controller, video: video)
      } else {
        DemoPlayerLayerView(player: controller.player)
          .accessibilityIdentifier("demo.player.surface")
      }

      playerPresentationOverlay
      if session.preferences.subtitlesEnabled
        && !audioOnly
        && session.preferences.playerDemoState == "Normal" {
        DemoCaptionOverlay(preferences: session.preferences)
      }

      if controller.state == .idle || controller.state == .loading {
        ProgressView()
          .controlSize(.large)
          .tint(.white)
          .accessibilityLabel("Loading Big Buck Bunny")
      }

      if case .failed(let message) = controller.state {
        VStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle")
            .font(.title2)
          Text(message)
            .font(.footnote)
            .multilineTextAlignment(.center)
          Button("Retry", action: controller.retry)
            .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
        .padding(24)
      }

      if autoplayTarget == nil {
        playerOptionsButton
      }

      if let autoplayTarget {
        DemoAutoplayCountdownOverlay(
          video: autoplayTarget,
          seconds: autoplaySeconds,
          onPlay: onAutoplayPlay,
          onCancel: onAutoplayCancel
        )
      }
    }
  }

  private var playerOptionsButton: some View {
    Button {
      optionsOpenedDuringPlayback =
        controller.player.timeControlStatus == .playing
      presentsPlayerOptions = true
    } label: {
      Image(systemName: "slider.horizontal.3")
        .font(.body.weight(.semibold))
        .frame(width: 38, height: 38)
        .background(.black.opacity(0.58), in: Circle())
        .overlay {
          Circle()
            .stroke(.white.opacity(0.22), lineWidth: 0.5)
        }
    }
    .buttonStyle(.plain)
    .foregroundStyle(.white)
    .contentShape(Circle())
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    .padding(10)
    .accessibilityLabel("Player options")
    .accessibilityHint("Opens playback, audio, track, and presentation settings")
    .accessibilityIdentifier("demo.player.inline-options")
  }
}
