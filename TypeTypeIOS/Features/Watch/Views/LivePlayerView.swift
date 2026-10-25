import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let dependencies: AppDependencies
  @ObservedObject private var preferences = LiveAppPreferencesStore.shared
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State private var showsOptions = false
  @State private var presentsDownload = false

  @State private var seekFeedback: PlayerDoubleTapSeekFeedback?
  @State private var swipeAdjustment: PlayerSwipeAdjustmentState?
  @State private var systemBrightnessBeforeSwipe: CGFloat?
  @State private var longPressBaseRate: Float?
  @State private var longPressBoostTask: Task<Void, Never>?
  @State private var horizontalSeekPreview: TimeInterval?
  @State private var autoPictureInPictureArmed = true
  @State private var autoPictureInPictureActive = false

  /// YouTube-style: when the player scrolls away (reading comments), float
  /// it into Picture in Picture automatically. Edge-triggered: one start per
  /// scroll-away, re-armed when the player is visible again.
  private func evaluateAutoPictureInPicture(_ frame: CGRect) {
    // Pull-down is only allowed while the page is at the top: the player
    // must sit below the status bar and well above the bottom edge.
    let screenH = UIScreen.main.bounds.height
    controller.isPlayerSurfaceFullyVisible =
      frame.minY >= 44 && frame.maxY <= screenH - 100
    let isAway = frame.maxY < frame.height * 0.3
    if !isAway {
      autoPictureInPictureArmed = true
      // Scrolled back to the player: return auto-started PiP inline. Only
      // auto-started windows restore here — a manual mini player stays.
      if autoPictureInPictureActive {
        autoPictureInPictureActive = false
        if controller.pictureInPicture.isEngaged {
          controller.pictureInPicture.bringInline()
        }
      }
      return
    }
    guard autoPictureInPictureArmed else { return }
    autoPictureInPictureArmed = false
    guard coordinator.hasActivePlayback,
      !controller.pictureInPicture.isEngaged
    else {
      return
    }
    autoPictureInPictureActive = true
    coordinator.startSystemPictureInPicture()
  }

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
          .overlay {
            LivePictureInPictureNotice(
              pictureInPicture: controller.pictureInPicture
            )
          }
          .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
          } action: { frame in
            evaluateAutoPictureInPicture(frame)
          }
          .onAppear {
            // A surface that reappears after a PiP round trip must not come
            // back with hidden controls.
            controller.pictureInPicture.markControlsRefresh()
          }
          // Seek and speed gestures live on the video surface only: as
          // container-level simultaneous gestures they also fired when
          // tapping controls, so double-tapping pause sought -10s.
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
          }
          .allowsHitTesting(false)
        }

        seekFeedbackOverlay
        horizontalSeekOverlay
        swipeAdjustmentOverlay
        statusOverlay
        // Above the transport controls on purpose: the UIKit player overlay
        // sits under the SwiftUI controls and never received taps on Skip.
        LiveSponsorBlockOverlay(
          controller: controller,
          fillsAvailableSpace: false
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 10)
        playbackStatusAccessibilityElement
        playbackPositionAccessibilityElement

        HStack(spacing: 10) {
          if let video = coordinator.currentVideo,
            let shareURL = LiveShareURLBuilder.video(
              serverURL: dependencies.serverStore.selectedServer()?.baseURL,
              sourceURL: video.url
            ) {
            ShareLink(item: shareURL) {
              overlayIcon("square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share")
            .accessibilityIdentifier("live.player.share")

            Button {
              presentsDownload = true
            } label: {
              overlayIcon("arrow.down.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Download")
            .accessibilityIdentifier("live.player.download")
          }

          Button {
            showsOptions = true
          } label: {
            overlayIcon("slider.horizontal.3")
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Player options")
          .accessibilityIdentifier("live.player.options")
        }
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .topTrailing
        )
        .padding(10)
        .opacity(controller.playerChromeVisible ? 1 : 0)
        .allowsHitTesting(controller.playerChromeVisible)
      }
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
    .sheet(isPresented: $presentsDownload) {
      if let video = coordinator.currentVideo {
        LiveDownloadSheet(video: video, dependencies: dependencies)
      }
    }
    .sheet(isPresented: $showsOptions) {
      LivePlayerOptionsSheet(
        controller: controller,
        coordinator: coordinator,
        dependencies: dependencies,
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
    // The transport controls sit in the middle band: a double tap there is
    // meant for the buttons and must never seek.
    guard location.x < width * 0.35 || location.x > width * 0.65 else {
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

/// Shown over the video surface while Picture in Picture is running: the
/// inline surface stays covered instead of rendering the video twice, and
/// the user can bring playback back into the app.
private struct LivePictureInPictureNotice: View {
  @ObservedObject var pictureInPicture: LivePictureInPictureDriver

  var body: some View {
    if pictureInPicture.isEngaged {
      ZStack {
        Color.black
        VStack(spacing: 12) {
          Image(systemName: "pip")
            .font(.system(size: 34, weight: .medium))
            .foregroundStyle(.white)
          Text("Playing in Picture in Picture")
            .font(.headline)
            .foregroundStyle(.white)
          Button("Show in Player") {
            pictureInPicture.bringInline()
          }
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("live.player.pip.bringInline")
        }
        .padding(24)
      }
      .accessibilityIdentifier("live.player.pip.notice")
    }
  }
}

private extension LivePlayerView {
  func overlayIcon(_ symbol: String) -> some View {
    Image(systemName: symbol)
      .font(.body.weight(.semibold))
      .foregroundStyle(.white)
      .frame(width: 38, height: 38)
      .background(.black.opacity(0.58), in: Circle())
      .overlay {
        Circle().stroke(.white.opacity(0.22), lineWidth: 0.5)
      }
  }
}
