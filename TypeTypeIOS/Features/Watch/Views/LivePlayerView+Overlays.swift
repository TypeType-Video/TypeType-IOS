import SwiftUI

extension LivePlayerView {
  @ViewBuilder
  var seekFeedbackOverlay: some View {
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
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .transition(.opacity)
    }
  }

  @ViewBuilder
  var swipeAdjustmentOverlay: some View {
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
  var horizontalSeekOverlay: some View {
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
      // The video's own thumbnail as the poster while it prepares; the
      // spinner rides on top of it, small.
      ZStack {
        if let poster = posterURL {
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
