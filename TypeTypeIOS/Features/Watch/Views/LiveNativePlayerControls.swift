import SwiftUI

struct LiveNativePlayerControls: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var controls: LiveNativeControlsState
  var isFullscreen = false
  var onFullscreen: () -> Void
  @State private var scrubPosition: TimeInterval?
  @State private var presentsChapters = false

  var body: some View {
    ZStack {
      if showsControls {
        LinearGradient(
          colors: [.black.opacity(0.35), .clear, .black.opacity(0.55)],
          startPoint: .top,
          endPoint: .bottom
        )
        .allowsHitTesting(false)
        playPauseButton
        timeline
          .frame(maxHeight: .infinity, alignment: .bottom)
      }
    }
    .animation(.easeOut(duration: 0.18), value: showsControls)
    .onChange(of: controller.state) {
      if controller.state == .playing {
        controls.scheduleHide()
      } else {
        controls.keepVisible()
      }
    }
  }

  private var showsControls: Bool {
    switch controller.state {
    case .ready, .paused: return true
    case .playing: return controls.visible || scrubPosition != nil
    case .idle, .loading, .failed: return false
    }
  }

  private var playPauseButton: some View {
    Button {
      controller.togglePlayback()
      controls.scheduleHide()
    } label: {
      Image(systemName: controller.state == .playing ? "pause.fill" : "play.fill")
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 64, height: 64)
        .background(.ultraThinMaterial, in: Circle())
        .environment(\.colorScheme, .dark)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(controller.state == .playing ? "Pause" : "Play")
    .accessibilityIdentifier("live.player.play-pause")
  }

  private var timeline: some View {
    HStack(spacing: 10) {
      Text(LivePlaybackChapterNavigator.clockText(seconds: Int(scrubPosition ?? controller.position)))
      Slider(
        value: Binding(
          get: { scrubPosition ?? controller.position },
          set: { scrubPosition = $0 }
        ),
        in: 0...max(controller.duration, 1)
      ) { editing in
        if editing {
          controls.keepVisible()
        } else if let target = scrubPosition {
          controller.seek(to: target)
          scrubPosition = nil
          controls.scheduleHide()
        }
      }
      .tint(.white)
      .accessibilityLabel("Playback position")
      .accessibilityIdentifier("live.player.timeline")
      // Bands ride the slider as an overlay: a GeometryReader in the row
      // layout would inflate the whole controls bar (and misplace it).
      .overlay(alignment: .center) {
        sponsorSegmentBands
      }
      Text(LivePlaybackChapterNavigator.clockText(seconds: Int(controller.duration)))
      // The chapter entry is always present (like the fullscreen toggle) —
      // it used to hide behind a non-empty gate and simply went missing.
      Button {
        presentsChapters = true
      } label: {
        Image(systemName: "list.bullet.rectangle")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 32, height: 32)
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(
          isPresented: $presentsChapters,
          // Full screen puts the bar by the bottom edge: the popover opens
          // upward there, downward everywhere else.
          attachmentAnchor: .point(.init(x: 0.5, y: isFullscreen ? 0.0 : 1.0)),
          arrowEdge: isFullscreen ? .bottom : .top
        ) {
          LivePlayerChaptersView(controller: controller) {
            presentsChapters = false
          }
          .frame(width: 320, height: 380)
          .presentationCompactAdaptation(.popover)
        }
        // The controls must stay up while the chapter list is open.
        .onChange(of: presentsChapters) {
          if presentsChapters {
            controls.keepVisible()
          } else {
            controls.scheduleHide()
          }
        }
        .accessibilityLabel("Chapters")
        .accessibilityIdentifier("live.player.chapters.open")
      Button {
        onFullscreen()
      } label: {
        Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
          .font(.system(size: 15, weight: .semibold))
          .frame(width: 32, height: 32)
          .padding(.horizontal, 8)
          .padding(.vertical, 12)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isFullscreen ? "Exit full screen" : "Full screen")
      .accessibilityIdentifier("live.player.fullscreen-toggle")
    }
    .font(.caption2)
    .monospacedDigit()
    .foregroundStyle(.white)
    .padding(.horizontal, isFullscreen ? 26 : 12)
    .padding(.bottom, isFullscreen ? 24 : 6)
  }

  /// SponsorBlock segments over the track — shown for the mark/skip
  /// categories (the policy filters disabled ones out), one colour per
  /// category, display-only (plan task 2.1).
  private var sponsorSegmentBands: some View {
    GeometryReader { proxy in
      ForEach(controller.visibleSponsorBlockWindows) { window in
        let span = max(controller.duration, 1)
        let start = min(max(window.start / span, 0), 1)
        let end = min(max(window.end / span, 0), 1)
        Capsule()
          .fill(sponsorBandColor(window.segment.category).opacity(0.55))
          .frame(
            width: max(proxy.size.width * (end - start), 3),
            height: 5
          )
          .position(
            x: proxy.size.width * (start + end) / 2,
            y: proxy.size.height / 2
          )
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func sponsorBandColor(_ category: String) -> Color {
    switch category {
    case "sponsor": return .systemOrange
    case "selfpromo": return .systemBlue
    case "interaction": return .systemPurple
    case "intro", "outro": return .systemGreen
    case "music", "music_offtopic": return .systemRed
    default: return .systemGray
    }
  }
}
