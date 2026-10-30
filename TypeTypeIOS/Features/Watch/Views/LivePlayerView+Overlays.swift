import SwiftUI

extension LivePlayerView {
  @ViewBuilder
  var seekFeedbackOverlay: some View {
    if let activeFeedback = seekFeedback {
      LivePlayerSeekHint(feedback: activeFeedback)
      .transition(.asymmetric(
        insertion: .opacity.animation(.easeOut(duration: 0.09)),
        removal: .opacity.animation(.easeOut(duration: 0.22))
      ))
      .task(id: activeFeedback.id) {
        try? await Task.sleep(for: .milliseconds(700))
        withAnimation(.easeOut(duration: 0.22)) {
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
  var gestureDebugHUD: some View {
    #if DEBUG
    VStack {
      Spacer()
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(
            Array(LivePlayerView.gestureLog.enumerated()),
            id: \.offset
          ) { _, entry in
            Text(entry)
              .font(.system(size: 9, weight: .medium).monospaced())
              .foregroundStyle(.yellow)
          }
        }
        .padding(6)
        Spacer()
      }
    }
    .allowsHitTesting(false)
    #endif
  }

  @ViewBuilder
  var speedBoostOverlay: some View {
    if let rate = speedBoostRate {
      VStack {
        Text(String(format: rate.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fx" : "%.1fx", rate))
          .font(.callout.weight(.bold))
          .monospacedDigit()
          .foregroundStyle(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(.black.opacity(0.72), in: Capsule())
          .padding(.top, 12)
        Text(
          "\(LivePlaybackChapterNavigator.clockText(seconds: Int(controller.position)))"
            + " / \(LivePlaybackChapterNavigator.clockText(seconds: Int(controller.duration)))"
        )
        .font(.caption.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.black.opacity(0.72), in: Capsule())
        .padding(.top, 6)
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .transition(.opacity)
    }
  }

  @ViewBuilder
  var swipeAdjustmentOverlay: some View {
    if let adjustment = swipeAdjustment {
      LivePlayerLevelOverlay(kind: adjustment.kind, fraction: adjustment.fraction)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(false)
      .transition(.opacity.combined(with: .scale(scale: 0.86)))
      .accessibilityHidden(true)
    }
  }

  @ViewBuilder
  var horizontalSeekOverlay: some View {
    if let preview = horizontalSeekPreview {
      LivePlayerSeekScrubOverlay(
        position: preview.position,
        isFine: preview.isFine,
        duration: controller.duration,
        storyboard: LivePlaybackPreviewFrames.best(controller.stream?.previewFrames ?? []),
        windows: controller.visibleSponsorBlockWindows,
        isFullscreen: showsFullscreenLayout
      )
      .transition(.opacity)
    }
  }

  var playbackStatusAccessibilityElement: some View {
    Color.clear
      .frame(width: 1, height: 1)
      .allowsHitTesting(false)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Playback status")
      .accessibilityIdentifier("live.player.container")
      .accessibilityValue(controller.accessibilityStatus)
  }

  var playbackPositionAccessibilityElement: some View {
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
  var statusOverlay: some View {
    switch controller.state {
    case .idle, .loading:
      ZStack {
        if !controller.extrasReleased, let poster = posterURL {
          LiveRemoteImage(url: poster)
            .opacity(0.55)
        }
        ProgressView()
          .controlSize(.large)
          .tint(.white)
      }
      .accessibilityLabel("Preparing video")
    case let .failed(message):
      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
          .font(.title2)
        Text(message)
          .font(.footnote)
          .multilineTextAlignment(.center)
        Button("Try again", action: controller.retry)
          .liveProminentButton()
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
