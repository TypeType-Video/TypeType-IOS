import SwiftUI

struct LiveSponsorBlockOverlay: View {
  @ObservedObject var controller: LivePlayerController
  var fillsAvailableSpace = true

  var body: some View {
    Group {
      if fillsAvailableSpace {
        timeline
          .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
          )
      } else {
        timeline
      }
    }
    // Keep a minimal size: Auto Layout collapses the host to 0 x 0 and the next banner cannot appear.
    .padding(1)
  }

  private var timeline: some View {
    TimelineView(
      .animation(
        minimumInterval: 0.25,
        paused: controller.state != .playing && controller.state != .paused
      )
    ) { _ in
      VStack(alignment: .trailing, spacing: 8) {
        if controller.sponsorBlockShowCurrentSegment,
          let window = controller.activeSponsorBlockWindow(
            at: controller.precisePosition
          ) {
          banner(for: window)
        }
        if let notice = controller.sponsorBlockNotice {
          automaticNotice(notice)
        }
      }
      .animation(.easeOut(duration: 0.2), value: controller.sponsorBlockNotice)
    }
  }

  // Same notice as the Android player: shown for 2.6 s after every automatic skip or mute.
  private func automaticNotice(_ notice: LiveSponsorBlockNotice) -> some View {
    HStack(spacing: 8) {
      Circle()
        .fill(LiveSponsorBlockPalette.color(for: notice.category))
        .frame(width: 8, height: 8)
      VStack(alignment: .leading, spacing: 1) {
        Text(notice.muted ? "Muted automatically" : "Skipped automatically")
          .font(.subheadline.weight(.medium))
        Text(LiveSponsorBlockPolicy.title(for: notice.category))
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.68))
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .fixedSize()
    .transition(.opacity)
    .task(id: notice.id) {
      try? await Task.sleep(for: .milliseconds(2_600))
      guard !Task.isCancelled, controller.sponsorBlockNotice?.id == notice.id else { return }
      controller.sponsorBlockNotice = nil
    }
    .accessibilityElement(children: .combine)
  }

  private func banner(
    for window: LiveSponsorBlockWindow
  ) -> some View {
    HStack(spacing: 9) {
      Image(systemName: "flag.fill")
        .foregroundStyle(.green)
      VStack(alignment: .leading, spacing: 1) {
        Text(
          LiveSponsorBlockPolicy.title(
            for: window.segment.category
          )
        )
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        Text("SponsorBlock")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.65))
      }
      .layoutPriority(1)
      if controller.canManuallySkipSponsorBlock(window) {
        Button {
          controller.seek(to: window.end)
        } label: {
          Label("Skip", systemImage: "forward.end.fill")
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(.white)
        .foregroundStyle(.black)
        .fixedSize()
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 11)
    .padding(.vertical, 8)
    .background(.black.opacity(0.76), in: Capsule())
    .overlay {
      Capsule().stroke(.white.opacity(0.16), lineWidth: 0.5)
    }
    .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
    .fixedSize(horizontal: true, vertical: true)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("live.player.sponsorblock")
  }
}
