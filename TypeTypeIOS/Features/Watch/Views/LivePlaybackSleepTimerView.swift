import SwiftUI

struct LivePlaybackSleepTimerView: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator

  var body: some View {
    List {
      Section {
        ForEach(Self.minuteOptions, id: \.self) { minutes in
          option(
            title: "\(minutes) minutes",
            selected: isSelected(minutes: minutes)
          ) {
            coordinator.startSleepTimer(minutes: minutes)
          }
        }
        option(
          title: "End of video",
          selected: coordinator.sleepTimer.mode == .endOfVideo
        ) {
          coordinator.stopAtEndOfVideo()
        }
      }

      if coordinator.sleepTimer.isActive {
        Section {
          Button(role: .destructive) {
            coordinator.cancelSleepTimer()
          } label: {
            Label("Turn off sleep timer", systemImage: "timer")
          }
        }
      }
    }
    .navigationTitle("Sleep timer")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.player.sleep-timer")
  }

  private func option(
    title: String,
    selected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      action()
    } label: {
      HStack {
        Text(title)
          .foregroundStyle(.primary)
        Spacer()
        if selected {
          Image(systemName: "checkmark")
            .foregroundStyle(.tint)
        }
      }
    }
    .accessibilityValue(selected ? "Selected" : "")
  }

  private func isSelected(minutes: Int) -> Bool {
    coordinator.sleepTimer.mode == .timed
      && coordinator.sleepTimer.duration == TimeInterval(minutes * 60)
  }

  private static let minuteOptions = [15, 30, 45, 60, 90]
}

struct LivePlaybackSleepTimerLink: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator

  var body: some View {
    NavigationLink {
      LivePlaybackSleepTimerView(coordinator: coordinator)
    } label: {
      LabeledContent(
        "Sleep timer",
        value: coordinator.sleepTimer.summary
      )
    }
    .accessibilityIdentifier("live.player.sleep-timer.open")
  }
}
