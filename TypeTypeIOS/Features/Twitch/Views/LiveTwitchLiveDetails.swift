import SwiftUI

struct LiveTwitchLiveDetails: View {
  let stream: LiveTwitchStream
  let onRewind: (LiveTwitchArchive, TimeInterval) -> Void
  @State private var dragged: TimeInterval?

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      VStack(alignment: .leading, spacing: 12) {
        meta(now: context.date)
        if let archive = stream.archive,
          let range = LiveTwitchArchiveTime.position(startedAt: archive.startedAt, now: context.date), range > 0 {
          rewind(archive: archive, range: range)
        }
      }
    }
  }

  private func meta(now: Date) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      if let started = LiveTwitchFormat.date(stream.startedAt) {
        Text("Live for \(Duration.seconds(now.timeIntervalSince(started)).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      let labels = [stream.game?.name].compactMap { $0 } + stream.tags
      if !labels.isEmpty {
        Text(verbatim: labels.joined(separator: " · "))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
  }

  private func rewind(archive: LiveTwitchArchive, range: TimeInterval) -> some View {
    let value = min(dragged ?? range, range)
    let behind = range - value
    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Label("Go back in the live", systemImage: "gobackward")
          .font(.subheadline.weight(.semibold))
        Spacer()
        (behind >= 1 ? Text("\(LiveTwitchFormat.clock(behind)) behind live") : Text("Live"))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      Slider(
        value: Binding(get: { value }, set: { dragged = $0 }),
        in: 0...range
      ) { editing in
        guard !editing, let picked = dragged else { return }
        dragged = nil
        if let target = LiveTwitchArchiveTime.rewindTarget(picked, range: range) {
          onRewind(archive, target)
        }
      }
      .accessibilityLabel(Text("Go back in the live"))
      .accessibilityValue(behind >= 1 ? Text("\(LiveTwitchFormat.clock(behind)) behind live") : Text("Live"))
      .accessibilityHint(Text("Moving back by more than 30 seconds opens the recording of this live."))
    }
  }
}
