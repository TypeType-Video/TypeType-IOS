import SwiftUI

struct LivePlaybackSleepTimerMenu<Label: View>: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  @ViewBuilder let label: () -> Label

  var body: some View {
    Menu {
      ForEach([15, 30, 60, 90], id: \.self) { minutes in
        choice(String(localized: "\(minutes) minutes"), selected: isSelected(minutes: minutes)) {
          coordinator.startSleepTimer(minutes: minutes)
        }
      }
      choice(String(localized: "End of video"), selected: coordinator.sleepTimer.mode == .endOfVideo) {
        coordinator.stopAtEndOfVideo()
      }
      if coordinator.sleepTimer.isActive {
        Divider()
        Button("Turn off sleep timer", systemImage: "timer.slash", role: .destructive) {
          coordinator.cancelSleepTimer()
        }
      }
    } label: {
      label()
    }
  }

  @ViewBuilder
  private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    if selected {
      Button(title, systemImage: "checkmark", action: action)
    } else {
      Button(title, action: action)
    }
  }

  private func isSelected(minutes: Int) -> Bool {
    coordinator.sleepTimer.mode == .timed
      && coordinator.sleepTimer.duration == TimeInterval(minutes * 60)
  }
}
