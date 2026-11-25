import AVKit
import SwiftUI

struct LiveNativePlayerControls: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var controls: LiveNativeControlsState
  var isFullscreen = false
  var onFullscreen: () -> Void
  var onOptions: () -> Void
  var onChapters: () -> Void
  var onLiveRewind: (LiveTwitchArchive, TimeInterval) -> Void = { _, _ in }
  var onGoLive: (String) -> Void = { _ in }
  @State private var scrubPosition: TimeInterval?

  var body: some View {
    ZStack {
      if showsControls {
        LinearGradient(
          colors: [.black.opacity(0.35), .clear, .black.opacity(0.55)],
          startPoint: .top,
          endPoint: .bottom
        )
        .allowsHitTesting(false)
        if controller.state != .loading {
          playPauseButton
        }
        bottomBar
          .frame(maxHeight: .infinity, alignment: .bottom)
        if let login = controller.stream?.twitchMedia?.recordingOwner {
          LivePlayerLiveBadge(behind: true) { onGoLive(login) }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, isFullscreen ? 26 : 10)
            .padding(.top, 2)
        }
        if !isFullscreen {
          Button {
            onOptions()
          } label: {
            Image(systemName: "slider.horizontal.3")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.white)
              .frame(width: 36, height: 36)
              .background(.ultraThinMaterial, in: Circle())
              .environment(\.colorScheme, .dark)
          }
          .buttonStyle(.plain)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(.horizontal, isFullscreen ? 26 : 10)
          .padding(.vertical, 10)
          .accessibilityLabel("Player options")
          .accessibilityIdentifier("live.player.options")
        }
      } else {
        LivePlayerAirPlayBadge(sendsSoundOnly: controller.nativePlayback != nil)
      }
    }
    .animation(.easeOut(duration: 0.18), value: showsControls)
    .onChange(of: controller.state) {
      switch controller.state {
      case .playing:
        controls.scheduleHide()
      case .loading where hasStarted:
        if controls.visible { controls.keepVisible() }
      default:
        controls.keepVisible()
      }
    }
  }

  private var showsControls: Bool {
    switch controller.state {
    case .ready, .paused: return true
    case .playing: return controls.visible || scrubPosition != nil
    // A seek buffers: the timeline stays so the new position remains readable until playback resumes.
    case .loading: return hasStarted && (controls.visible || scrubPosition != nil)
    case .idle, .failed: return false
    }
  }

  // AVPlayer has no first-frame flag here: once it drives the page, a seek or a stall keeps the bar readable.
  private var hasStarted: Bool {
    controller.nativePlayback?.hasStarted == true || controller.nativePlayback == nil
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

  private var bottomBar: some View {
    HStack(spacing: 10) {
      if controller.isLiveStream {
        LivePlayerLiveTrack(controller: controller, controls: controls, onRewind: onLiveRewind)
      } else {
        timeline
      }
      trailingButtons
    }
    .font(.caption2)
    .monospacedDigit()
    .foregroundStyle(.white)
    // Over a 16:9 picture the bar keeps room for its track: past this size the times alone would fill it.
    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    .padding(.horizontal, isFullscreen ? 26 : 12)
    .padding(.bottom, isFullscreen ? 24 : 6)
  }

  private var timeline: some View {
    HStack(spacing: 10) {
      Text(LivePlaybackChapterNavigator.clockText(seconds: Int(scrubPosition ?? controller.position)))
      LivePlayerTimelineBar(
        position: scrubPosition ?? controller.position,
        duration: controller.duration,
        icon: LiveSeekbarIcon(settings: controller.settings),
        isScrubbing: scrubPosition != nil,
        onScrub: { target in
          if scrubPosition == nil { controls.keepVisible() }
          scrubPosition = target
        },
        onScrubEnded: { target in
          controller.seek(to: target)
          scrubPosition = nil
          controls.scheduleHide()
        },
        marks: { LivePlayerSponsorSegmentBands(controller: controller) }
      )
      .accessibilityIdentifier("live.player.timeline")
      .overlay {
        if let scrubPosition {
          LivePlayerTimelineScrubPreview(position: scrubPosition, controller: controller)
        }
      }
      Text(LivePlaybackChapterNavigator.clockText(seconds: Int(controller.duration)))
    }
  }
}
