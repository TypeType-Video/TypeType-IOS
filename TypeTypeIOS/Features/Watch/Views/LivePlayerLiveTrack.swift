import SwiftUI

// The bottom bar of a live: the whole broadcast from its start to now, the thumb at the live edge. Dragging back
// opens the recording at that moment, as on the web; without a recording only the live badge and the time remain.
struct LivePlayerLiveTrack: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject var controls: LiveNativeControlsState
  let onRewind: (LiveTwitchArchive, TimeInterval) -> Void
  @State private var scrubPosition: TimeInterval?

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      HStack(spacing: 10) {
        if let scrubPosition, let range = rewindRange(now: context.date) {
          Text(verbatim: "-" + LiveTwitchFormat.clock(max(0, range - scrubPosition)))
            .frame(minWidth: 44, alignment: .leading)
        } else {
          liveBadge
        }
        if let archive, let range = rewindRange(now: context.date) {
          track(archive: archive, range: range)
        } else {
          Spacer(minLength: 0)
        }
        if let elapsed = elapsed(now: context.date) {
          Text(verbatim: LiveTwitchFormat.clock(elapsed))
            .accessibilityLabel(Text("Live for \(LiveTwitchFormat.clock(elapsed))"))
        }
      }
    }
  }

  private var live: LiveTwitchStream? {
    controller.stream?.twitchMedia?.live
  }

  private var archive: LiveTwitchArchive? {
    live?.archive
  }

  private var liveBadge: some View {
    LivePlayerLiveBadge(behind: controller.isBehindLiveEdge) {
      controller.goToLiveEdge()
      controls.scheduleHide()
    }
  }

  private func track(archive: LiveTwitchArchive, range: TimeInterval) -> some View {
    LivePlayerTimelineBar(
      position: scrubPosition ?? range,
      duration: range,
      icon: LiveSeekbarIcon(settings: controller.settings),
      isScrubbing: scrubPosition != nil,
      onScrub: { target in
        if scrubPosition == nil { controls.keepVisible() }
        scrubPosition = target
      },
      onScrubEnded: { target in
        scrubPosition = nil
        controls.scheduleHide()
        if let position = LiveTwitchArchiveTime.rewindTarget(target, range: range) {
          onRewind(archive, position)
        }
      },
      marks: { EmptyView() }
    )
    .accessibilityLabel(Text("Go back in the live"))
    .accessibilityValue(Text("Live"))
    .accessibilityHint(Text("Moving back by more than 30 seconds opens the recording of this live."))
    .accessibilityAction(named: Text("Go back one minute")) {
      if let position = LiveTwitchArchiveTime.rewindTarget(range - 60, range: range) {
        onRewind(archive, position)
      }
    }
    .accessibilityIdentifier("live.player.live-track")
  }

  private func rewindRange(now: Date) -> TimeInterval? {
    guard let archive, let range = LiveTwitchArchiveTime.position(startedAt: archive.startedAt, now: now), range > 0 else {
      return nil
    }
    return range
  }

  private func elapsed(now: Date) -> TimeInterval? {
    guard let started = live.flatMap({ LiveTwitchFormat.date($0.startedAt) }) else { return nil }
    return max(0, now.timeIntervalSince(started))
  }
}

// Red at the live edge; grey and tappable once behind it, or from the recording of a live still going on.
struct LivePlayerLiveBadge: View {
  let behind: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        Circle()
          .fill(behind ? Color.white.opacity(0.7) : Color.red)
          .frame(width: 7, height: 7)
        Text(behind ? "Go live" : "LIVE")
          .font(.caption2.weight(.heavy))
          .lineLimit(1)
      }
      .fixedSize()
      .padding(.horizontal, 9)
      .padding(.vertical, 5)
      .background(.ultraThinMaterial, in: Capsule())
      .environment(\.colorScheme, .dark)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!behind)
    .accessibilityLabel(behind ? Text("Go live") : Text("Live"))
    .accessibilityHint(behind ? Text("Jumps to the latest moment of the live.") : Text(verbatim: ""))
    .accessibilityIdentifier("live.player.live-edge")
  }
}
