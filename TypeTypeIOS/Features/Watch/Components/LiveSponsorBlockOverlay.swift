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
      if controller.sponsorBlockShowCurrentSegment,
        let window = controller.activeSponsorBlockWindow(
          at: controller.precisePosition
        ) {
        banner(for: window)
      }
    }
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
