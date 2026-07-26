import SwiftUI

struct DemoSponsorBlockOverlay: View {
  @EnvironmentObject private var session: DemoSessionStore
  @ObservedObject var controller: DemoPlayerController
  let video: DemoVideo
  @State private var isInsideSegment = false
  @State private var didAutoSkip = false
  @State var didMute = false
  var body: some View {
    ZStack {
      if didAutoSkip {
        banner {
          HStack(spacing: 8) {
            Label(skipConfirmation, systemImage: "forward.end.fill")
            Button("Undo") {
              didAutoSkip = false
              controller.seek(to: segment.start)
            }
            .fontWeight(.semibold)
          }
        }
      } else if isInsideSegment {
        banner {
          HStack(spacing: 8) {
            Label(
              segmentLabel,
              systemImage: didMute ? "speaker.slash.fill" : "flag.fill"
            )
            if showsManualSkip {
              Button(segment.isFullVideo ? "Skip video" : "Skip") {
                controller.seek(to: segment.end)
                isInsideSegment = false
              }
              .fontWeight(.semibold)
            }
          }
        }
      }
    }
    .task(id: taskIdentity) {
      await monitorPlayback()
    }
    .onDisappear(perform: restoreAudio)
    .accessibilityIdentifier("demo.player.sponsorblock")
  }
  private func banner<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    content()
      .font(.caption)
      .foregroundStyle(.white)
      .padding(.horizontal, 11)
      .padding(.vertical, 7)
      .background(Color.green.opacity(0.86))
      .clipShape(Capsule())
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  private func monitorPlayback() async {
    while !Task.isCancelled {
      let seconds = controller.player.currentTime().seconds
      let inside = isInsideSegmentRange(at: seconds)
      if inside && shouldAutoSkip && session.preferences.sponsorBlockMutesInsteadOfSkips {
        controller.player.isMuted = true
        didMute = true
        isInsideSegment =
          session.preferences.sponsorBlockShowsCurrentSegment && isLabelVisible
      } else if inside && shouldAutoSkip && !didAutoSkip {
        restoreAudio()
        didAutoSkip = true
        isInsideSegment = false
        controller.seek(to: segment.end)
      } else {
        if !inside { restoreAudio() }
        isInsideSegment = inside && shouldShowLabel
      }
      try? await Task.sleep(for: .milliseconds(250))
    }
  }
  private func isInsideSegmentRange(at seconds: Double) -> Bool {
    guard seconds.isFinite, seconds >= segment.start, seconds < segment.end else {
      return false
    }
    return action != "Hide"
      && segment.end - segment.start
        >= Double(session.preferences.sponsorBlockMinimumDuration)
  }
  private var isLabelVisible: Bool {
    DemoSponsorBlockPolicy.isVisible(
      segment,
      action: action,
      minimumDuration: session.preferences.sponsorBlockMinimumDuration,
      showsFullVideoLabels: session.preferences.sponsorBlockShowsFullVideoLabels
    )
  }
  private var shouldAutoSkip: Bool {
    DemoSponsorBlockPolicy.shouldAutoSkip(
      segment,
      action: action,
      minimumDuration: session.preferences.sponsorBlockMinimumDuration,
      manualFullVideoSkip: session.preferences.sponsorBlockManualFullVideoSkip,
      skipsNonMusicOnlyOnMusicVideos: session.preferences.sponsorBlockMusicOnly,
      isMusicVideo: isMusicVideo
    )
  }
  private var shouldShowLabel: Bool {
    isLabelVisible
      && (
        segment.isFullVideo
          || (
            session.preferences.sponsorBlockShowsCurrentSegment
              && (action == "Mark" || (action == "Skip" && !shouldAutoSkip))
          )
      )
  }
  private var showsManualSkip: Bool {
    !didMute && action != "Hide" && (!shouldAutoSkip || action == "Mark")
  }

  private var action: String {
    session.preferences.sponsorBlockCategoryActions[segment.category]
      ?? session.preferences.sponsorBlockMode
  }

  private var segment: DemoSponsorBlockSegment {
    if video.id == "private-home" {
      return .init(
        category: "exclusive_access",
        start: 0,
        end: duration,
        isFullVideo: true
      )
    }
    let category = ["typetype-design", "open-source-weekly"].contains(video.id)
      ? "music_offtopic"
      : "sponsor"
    return .init(category: category, start: 4, end: 18, isFullVideo: false)
  }

  private var duration: Double {
    let parts = video.duration.split(separator: ":").compactMap { Double($0) }
    return parts.reduce(0) { $0 * 60 + $1 }
  }

  private var isMusicVideo: Bool {
    video.id == "open-source-weekly"
  }

  private var segmentLabel: String {
    if didMute { return "SponsorBlock segment muted" }
    if segment.isFullVideo { return "Full-video SponsorBlock label" }
    return segment.category == "music_offtopic"
      ? "Non-music segment"
      : "Sponsor segment"
  }

  private var skipConfirmation: String {
    segment.isFullVideo
      ? "Full-video segment skipped"
      : "Sponsor skipped · 14s"
  }

  private var taskIdentity: String {
    "\(video.id)-\(action)-\(session.preferences.sponsorBlockMinimumDuration)-"
      + "\(session.preferences.sponsorBlockShowsFullVideoLabels)-"
      + "\(session.preferences.sponsorBlockManualFullVideoSkip)-"
      + "\(session.preferences.sponsorBlockMusicOnly)-"
      + "\(session.preferences.sponsorBlockMutesInsteadOfSkips)"
  }
}
