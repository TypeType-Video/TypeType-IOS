import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State private var showsOptions = false

  var body: some View {
    ZStack {
      Color.black

      LivePlayerLayerView(
        player: controller.player,
        controller: controller
      )
        .accessibilityIdentifier("live.player.surface")

      if controller.audioOnly {
        ZStack {
          LiveRemoteImage(url: posterURL)
            .scaledToFill()
            .blur(radius: 28)
            .opacity(0.48)
            .clipped()
          Image(systemName: "waveform")
            .font(.system(size: 44, weight: .medium))
            .foregroundStyle(.white)
            .symbolEffect(.variableColor.iterative)
        }
        .allowsHitTesting(false)
      }

      statusOverlay
      playbackStatusAccessibilityElement

      Button {
        showsOptions = true
      } label: {
        Image(systemName: "slider.horizontal.3")
          .font(.body.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 38, height: 38)
          .background(.black.opacity(0.58), in: Circle())
          .overlay {
            Circle().stroke(.white.opacity(0.22), lineWidth: 0.5)
          }
      }
      .buttonStyle(.plain)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topTrailing
      )
      .padding(10)
      .accessibilityLabel("Player options")
      .accessibilityIdentifier("live.player.options")
    }
    .aspectRatio(16 / 9, contentMode: .fit)
    .clipShape(
      RoundedRectangle(
        cornerRadius: cinemaMode ? 0 : 16,
        style: .continuous
      )
    )
    .sheet(isPresented: $showsOptions) {
      LivePlayerOptionsSheet(
        controller: controller,
        coordinator: coordinator,
        cinemaMode: $cinemaMode
      )
    }
  }

  private var playbackStatusAccessibilityElement: some View {
    Color.clear
      .frame(width: 1, height: 1)
      .allowsHitTesting(false)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Playback status")
      .accessibilityIdentifier("live.player.container")
      .accessibilityValue(controller.accessibilityStatus)
  }

  @ViewBuilder
  private var statusOverlay: some View {
    switch controller.state {
    case .idle, .loading:
      ProgressView()
        .controlSize(.large)
        .tint(.white)
        .accessibilityLabel("Preparing video")
    case let .failed(message):
      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
          .font(.title2)
        Text(message)
          .font(.footnote)
          .multilineTextAlignment(.center)
        Button("Try again", action: controller.retry)
          .buttonStyle(.borderedProminent)
      }
      .foregroundStyle(.white)
      .padding(24)
      .background(.black.opacity(0.82))
      .clipShape(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .padding(18)
    case .ready, .playing, .paused:
      EmptyView()
    }
  }
}
