import AVKit
import SwiftUI

struct LiveNativePlayerControls: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var controls: LiveNativeControlsState
  var isFullscreen = false
  var onFullscreen: () -> Void
  var onOptions: () -> Void
  var onChapters: () -> Void
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
        timeline
          .frame(maxHeight: .infinity, alignment: .bottom)
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

  private var hasStarted: Bool {
    controller.nativePlayback?.hasStarted == true || controller.isOfflineContent
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
      AirPlayRouteButton { controls.hold($0) }
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
      if !controller.displayedChapters.isEmpty {
        Button {
          onChapters()
        } label: {
          Image(systemName: "list.bullet.rectangle")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 32, height: 32)
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Chapters")
        .accessibilityIdentifier("live.player.chapters.open")
      }
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
}
