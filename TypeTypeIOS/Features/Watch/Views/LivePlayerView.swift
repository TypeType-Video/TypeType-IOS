import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State private var showsOptions = false
  @State private var seekFeedback: PlayerDoubleTapSeekFeedback?
  @State private var swipeAdjustment: PlayerSwipeAdjustmentState?
  @State private var systemBrightnessBeforeSwipe: CGFloat?

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black

        LivePlayerLayerView(
          player: controller.player,
          controller: controller
        ) { event in
          handleSwipeAdjustment(event)
        }
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

        seekFeedbackOverlay
        swipeAdjustmentOverlay
        statusOverlay
        playbackStatusAccessibilityElement
        playbackPositionAccessibilityElement

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
      .simultaneousGesture(
        SpatialTapGesture(count: 2)
          .onEnded { value in
            handleDoubleTap(
              at: value.location,
              width: proxy.size.width
            )
          }
      )
    }
    .aspectRatio(16 / 9, contentMode: .fit)
    .clipShape(
      RoundedRectangle(
        cornerRadius: cinemaMode ? 0 : 16,
        style: .continuous
      )
    )
    .onDisappear {
      restoreSystemBrightness()
    }
    .sheet(isPresented: $showsOptions) {
      LivePlayerOptionsSheet(
        controller: controller,
        coordinator: coordinator,
        cinemaMode: $cinemaMode
      )
    }
  }

  private func handleDoubleTap(
    at location: CGPoint,
    width: CGFloat
  ) {
    guard let direction = PlayerDoubleTapSeek.direction(
      x: location.x,
      width: width
    ), let target = PlayerDoubleTapSeek.target(
      current: controller.position,
      duration: controller.duration,
      direction: direction
    ) else {
      return
    }

    seekFeedback = PlayerDoubleTapSeekFeedback(
      direction: direction,
      seconds: Self.doubleTapSeconds
    )
    controller.seek(to: target)
  }

  private func handleSwipeAdjustment(
    _ event: PlayerSwipeAdjustmentEvent
  ) {
    switch event {
    case let .began(kind, fraction):
      if kind == .brightness {
        systemBrightnessBeforeSwipe = UIScreen.main.brightness
      }
      swipeAdjustment = PlayerSwipeAdjustmentState(
        kind: kind,
        fraction: fraction
      )
    case let .updated(kind, fraction):
      swipeAdjustment = PlayerSwipeAdjustmentState(
        kind: kind,
        fraction: fraction
      )
      applySwipeAdjustment(kind: kind, fraction: fraction)
    case .ended:
      swipeAdjustment = nil
    }
  }

  private func applySwipeAdjustment(
    kind: PlayerSwipeAdjustmentKind,
    fraction: CGFloat
  ) {
    switch kind {
    case .brightness:
      UIScreen.main.brightness = fraction
    case .volume:
      controller.player.volume = Float(fraction)
    }
  }

  private func restoreSystemBrightness() {
    if let brightness = systemBrightnessBeforeSwipe {
      UIScreen.main.brightness = brightness
      systemBrightnessBeforeSwipe = nil
    }
  }

  @ViewBuilder
  private var seekFeedbackOverlay: some View {
    if let activeFeedback = seekFeedback {
      HStack {
        if activeFeedback.direction == .forward {
          Spacer(minLength: 0)
        }
        Label(
          activeFeedback.direction == .back
            ? "-\(activeFeedback.seconds)s"
            : "+\(activeFeedback.seconds)s",
          systemImage: activeFeedback.direction == .back
            ? "arrow.counterclockwise"
            : "arrow.clockwise"
        )
        .font(.headline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.68), in: Capsule())
        .padding(
          activeFeedback.direction == .back ? .leading : .trailing,
          42
        )
        if activeFeedback.direction == .back {
          Spacer(minLength: 0)
        }
      }
      .allowsHitTesting(false)
      .transition(.opacity)
      .task(id: activeFeedback.id) {
        try? await Task.sleep(for: .milliseconds(650))
        withAnimation(.easeOut(duration: 0.12)) {
          let pulse = activeFeedback.pulse
          if seekFeedback?.pulse == pulse {
            seekFeedback = nil
          }
        }
      }
      .accessibilityHidden(true)
    }
  }

  @ViewBuilder
  private var swipeAdjustmentOverlay: some View {
    if let adjustment = swipeAdjustment {
      HStack {
        if adjustment.kind == .volume {
          Spacer(minLength: 0)
        }
        VStack(spacing: 6) {
          Image(
            systemName: adjustment.kind == .brightness
              ? "sun.max.fill"
              : "speaker.wave.2.fill"
          )
          Text("\(adjustment.percent)%")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.68), in: Capsule())
        .padding(.horizontal, 28)
        if adjustment.kind == .brightness {
          Spacer(minLength: 0)
        }
      }
      .allowsHitTesting(false)
      .transition(.opacity)
      .accessibilityHidden(true)
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

  private var playbackPositionAccessibilityElement: some View {
    Color.clear
      .frame(width: 1, height: 1)
      .allowsHitTesting(false)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Playback position")
      .accessibilityIdentifier("live.player.position")
      .accessibilityValue(
        "\(Int(controller.position.rounded(.down)))"
      )
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

  private static let doubleTapSeconds =
    PlayerDoubleTapSeek.seconds
}
