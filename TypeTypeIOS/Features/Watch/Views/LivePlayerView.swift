import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var coordinator: LivePlaybackCoordinator
  let dependencies: AppDependencies
  @ObservedObject var preferences = LiveAppPreferencesStore.shared
  let posterURL: URL?
  @Binding var cinemaMode: Bool
  @State var showsOptions = false

  @State var seekFeedback: PlayerDoubleTapSeekFeedback?
  @State var doubleTapSeek: (target: TimeInterval, seconds: Int, direction: PlayerDoubleTapSeekDirection, at: Date)?
  @State var doubleTapSeekTask: Task<Void, Never>?
  @State var swipeAdjustment: PlayerSwipeAdjustmentState?
  @State var systemBrightnessBeforeSwipe: CGFloat?
  @State var longPressBaseRate: Float?
  @State var longPressBoostTask: Task<Void, Never>?
  @State var horizontalSeekPreview: TimeInterval?
  @State var autoPictureInPictureArmed = true
  @State var autoPictureInPictureActive = false


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

        Button {
          showsOptions = true
        } label: {
          overlayIcon("slider.horizontal.3")
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
        dependencies: dependencies,
        cinemaMode: $cinemaMode
      )
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
