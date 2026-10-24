import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  @ObservedObject private var preferences = LiveAppPreferencesStore.shared
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State private var showsOptions = false
  @State private var seekFeedback: PlayerDoubleTapSeekFeedback?
  @State private var swipeAdjustment: PlayerSwipeAdjustmentState?
  @State private var systemBrightnessBeforeSwipe: CGFloat?
  @State private var longPressBaseRate: Float?
  @State private var longPressBoostTask: Task<Void, Never>?
  @State private var horizontalSeekPreview: TimeInterval?

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black

        LivePlayerLayerView(
          player: controller.player,
          controller: controller,
          onSwipeAdjustment: { event in
            handleSwipeAdjustment(event)
          },
          onHorizontalSeek: { event in
            handleHorizontalSeek(event)
          },
          onPictureInPictureUIRestore: { completion in
            PictureInPictureRestore.restore(
              canRestore: coordinator.hasActivePlayback,
              prepare: {
                coordinator.expand()
              },
              isPrepared: {
                coordinator.presentation == .expanded
              },
              completion: completion
            )
          }
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

        seekFeedbackOverlay
        horizontalSeekOverlay
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
      .onLongPressGesture(
        minimumDuration: 0.35,
        perform: {},
        onPressingChanged: { pressing in
          setLongPressBoost(active: pressing)
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
    .overlay(alignment: .top) {
      if let remaining = coordinator.autoplayCountdownRemaining {
        HStack(spacing: 10) {
          Text("Next video in \(remaining)s")
            .font(.footnote.weight(.semibold))
            .monospacedDigit()
          Button("Play now") {
            coordinator.skipAutoplayCountdown()
          }
          .font(.footnote.weight(.semibold))
          Button("Cancel", role: .destructive) {
            coordinator.cancelAutoplayCountdown()
          }
          .font(.footnote)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.82), in: Capsule())
        .padding(.top, 10)
        .accessibilityIdentifier("live.player.autoplay-countdown")
      }
    }
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
    guard !preferences.preferences.playerAccessibleControlsEnabled,
      preferences.preferences.playerDoubleTapSeekEnabled
    else {
      return
    }
    guard let direction = PlayerDoubleTapSeek.direction(
      x: location.x,
      width: width
    ), let target = PlayerDoubleTapSeek.target(
      current: controller.position,
      duration: controller.duration,
      direction: direction,
      seconds: preferences.preferences.playerDoubleTapSeekSeconds
    ) else {
      return
    }

    seekFeedback = PlayerDoubleTapSeekFeedback(
      direction: direction,
      seconds: preferences.preferences.playerDoubleTapSeekSeconds
    )
    controller.seek(to: target)
  }

  private func handleSwipeAdjustment(
    _ event: PlayerSwipeAdjustmentEvent
  ) {
    guard preferences.preferences.playerSwipeBrightnessVolumeEnabled else {
      return
    }
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

  private func handleHorizontalSeek(
    _ event: PlayerHorizontalSeekEvent
  ) {
    switch event {
    case let .began(position):
      horizontalSeekPreview = position
    case let .updated(position):
      horizontalSeekPreview = position
    case let .ended(position):
      horizontalSeekPreview = nil
      controller.seek(to: position)
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

  private func setLongPressBoost(active: Bool) {
    guard preferences.preferences.playerLongPressSpeedEnabled else { return }
    longPressBoostTask?.cancel()
    longPressBoostTask = nil
    if active {
      // The press callback fires at touch-down, while the long press only
      // counts after its threshold. Starting the boost immediately made
      // every tap change the playback rate twice — a visible stall — and
      // swallowed taps on overlay buttons such as SponsorBlock prompts.
      longPressBoostTask = Task {
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard !Task.isCancelled else { return }
        self.longPressBaseRate = self.controller.playbackRate
        self.controller.setPlaybackRate(2)
      }
    } else if let baseRate = longPressBaseRate {
      controller.setPlaybackRate(baseRate)
      longPressBaseRate = nil
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

  @ViewBuilder
  private var horizontalSeekOverlay: some View {
    if let preview = horizontalSeekPreview {
      VStack(spacing: 6) {
        Text(LiveVideoMetadataFormatter.duration(Int64(preview.rounded())))
          .font(.headline.weight(.semibold))
          .monospacedDigit()
        Text("Release to seek")
          .font(.caption2)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(.black.opacity(0.72), in: Capsule())
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

}
