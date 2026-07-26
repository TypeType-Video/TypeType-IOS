import SwiftUI

struct DemoAutoplayCountdownOverlay: View {
  let video: DemoVideo
  let seconds: Int
  let onPlay: () -> Void
  let onCancel: () -> Void
  @State private var deadline: Date
  @State private var isPaused = false
  @State private var pauseStartedAt: Date?

  init(
    video: DemoVideo,
    seconds: Int,
    onPlay: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.video = video
    self.seconds = seconds
    self.onPlay = onPlay
    self.onCancel = onCancel
    _deadline = State(
      initialValue: .now.addingTimeInterval(TimeInterval(max(0, seconds)))
    )
  }

  var body: some View {
    TimelineView(
      .animation(minimumInterval: 1 / 30, paused: isPaused)
    ) { context in
      overlay(at: effectiveDate(context.date))
    }
    .task {
      while !Task.isCancelled {
        if !isPaused, remaining(at: .now) <= 0 {
          onPlay()
          return
        }
        try? await Task.sleep(for: .milliseconds(50))
      }
    }
    .accessibilityIdentifier("demo.autoplay.countdown")
  }

  private func overlay(at date: Date) -> some View {
    ZStack {
      DemoArtworkView(video: video)
        .scaledToFill()
        .opacity(0.72)
      Color.black.opacity(0.54)
      LinearGradient(
        colors: [.clear, .black.opacity(0.92)],
        startPoint: .center,
        endPoint: .bottom
      )

      VStack {
        HStack {
          Spacer()
          Button(action: onCancel) {
            Image(systemName: "xmark")
              .font(.subheadline.weight(.bold))
              .frame(width: 34, height: 34)
              .background(.black.opacity(0.48), in: Circle())
          }
          .accessibilityLabel("Cancel autoplay")
        }
        Spacer()
        VStack(alignment: .leading, spacing: 8) {
          Text(countdownLabel(at: date))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.72))
          Text(video.title)
            .font(.headline)
            .lineLimit(2)
          Text(video.channel)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.68))
          HStack {
            Button("Play now", action: onPlay)
              .buttonStyle(.borderedProminent)
            Button(isPaused ? "Resume" : "Pause", action: togglePause)
            .buttonStyle(.bordered)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(14)
    }
    .foregroundStyle(.white)
    .clipped()
    .overlay(alignment: .bottom) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.white.opacity(0.22))
          Capsule()
            .fill(DemoTheme.accent)
            .frame(width: geometry.size.width * progress(at: date))
            .shadow(color: DemoTheme.accent.opacity(0.5), radius: 3)
        }
      }
      .frame(height: 4)
      .padding(.horizontal, 14)
      .padding(.bottom, 7)
    }
  }

  private func remaining(at date: Date) -> TimeInterval {
    max(0, deadline.timeIntervalSince(date))
  }

  private func progress(at date: Date) -> Double {
    guard seconds > 0 else { return 1 }
    return min(1, max(0, 1 - remaining(at: date) / Double(seconds)))
  }

  private func countdownLabel(at date: Date) -> String {
    if isPaused {
      return "Autoplay paused"
    }
    return "Up next in \(Int(ceil(remaining(at: date))))s"
  }

  private func effectiveDate(_ date: Date) -> Date {
    isPaused ? pauseStartedAt ?? date : date
  }

  private func togglePause() {
    let now = Date.now
    if isPaused {
      if let pauseStartedAt {
        deadline = deadline.addingTimeInterval(
          now.timeIntervalSince(pauseStartedAt)
        )
      }
      self.pauseStartedAt = nil
      isPaused = false
    } else {
      pauseStartedAt = now
      isPaused = true
    }
  }
}
