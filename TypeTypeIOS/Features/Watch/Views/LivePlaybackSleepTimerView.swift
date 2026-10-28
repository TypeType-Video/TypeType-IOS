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
      .liveThemedList()
      .liveThemeRepaint()
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

  private static let minuteOptions = [30, 60, 90]
}


/// Compact popup for the actions-row button. The full page keeps its List;
/// a List inside a popover clips its rows, so this one is sized to content.
struct LivePlaybackSleepTimerPopover: View {
  @ObservedObject var coordinator: LivePlaybackCoordinator
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach([30, 60, 90], id: \.self) { minutes in
        row(
          title: "\(minutes) minutes",
          selected: isSelected(minutes: minutes)
        ) {
          coordinator.startSleepTimer(minutes: minutes)
          dismiss()
        }
        divider
      }
      row(
        title: "End of video",
        selected: coordinator.sleepTimer.mode == .endOfVideo
      ) {
        coordinator.stopAtEndOfVideo()
        dismiss()
      }
      if coordinator.sleepTimer.isActive {
        divider
        row(title: "Turn off sleep timer", selected: false, destructive: true) {
          coordinator.cancelSleepTimer()
          dismiss()
        }
      }
    }
    .frame(width: 280)
    .presentationCompactAdaptation(.popover)
    .accessibilityIdentifier("live.player.sleep-timer.popover")
  }

  private func row(
    title: String,
    selected: Bool,
    destructive: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      action()
    } label: {
      HStack(spacing: 12) {
        Text(title)
          .foregroundStyle(destructive ? Color.systemRed : .primary)
        Spacer(minLength: 12)
        if selected {
          Image(systemName: "checkmark")
            .foregroundStyle(DemoTheme.accent)
        }
      }
      .padding(.horizontal, 16)
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var divider: some View {
    Rectangle()
      .fill(DemoTheme.separator)
      .frame(height: 1)
      .padding(.horizontal, 16)
  }

  private func isSelected(minutes: Int) -> Bool {
    coordinator.sleepTimer.mode == .timed
      && coordinator.sleepTimer.duration == TimeInterval(minutes * 60)
  }
}
