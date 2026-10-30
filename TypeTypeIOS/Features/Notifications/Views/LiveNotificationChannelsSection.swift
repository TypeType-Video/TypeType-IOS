import SwiftUI

struct LiveNotificationChannelsSection: View {
  @ObservedObject var viewModel: LiveNotificationSettingsViewModel
  let channels: [LiveNotificationChannel]
  @Environment(\.themePalette) private var palette

  var body: some View {
    LiveSection {
      ForEach(channels) { channel in
        Toggle(isOn: binding(for: channel.preference)) {
          HStack(spacing: 12) {
            LiveRemoteImage(url: channel.avatarURL)
              .frame(width: 32, height: 32)
              .clipShape(Circle())
              .accessibilityHidden(true)
            Text(channel.name)
              .lineLimit(1)
          }
        }
        .liveRowFill()
        .disabled(viewModel.isBulkUpdating || viewModel.updatingURLs.contains(channel.id))
        .accessibilityIdentifier("live.notification-settings.\(channel.id)")
      }
    } header: {
      HStack(spacing: 12) {
        Text("Channels").liveSettingsHeader()
        bulkButton("Turn all on", enabled: viewModel.canEnableAll) {
          Task { await viewModel.setAllEnabled(true) }
        }
        .accessibilityIdentifier("live.notification-settings.enable-all")
        bulkButton("Turn all off", enabled: viewModel.canDisableAll) {
          Task { await viewModel.setAllEnabled(false) }
        }
        .accessibilityIdentifier("live.notification-settings.disable-all")
      }
    } footer: {
      if let note = LiveNotificationTexts.note(for: viewModel.limit) {
        Text(note)
          .liveSettingsFooter()
          .accessibilityIdentifier("live.notification-settings.budget")
      }
    }
  }

  private func bulkButton(
    _ title: LocalizedStringKey,
    enabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(enabled ? palette.accent : Color.secondary)
        .fixedSize()
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
  }

  private func binding(for preference: LiveChannelNotificationPreference) -> Binding<Bool> {
    Binding(
      get: { preference.enabled },
      set: { enabled in Task { await viewModel.setEnabled(enabled, for: preference) } }
    )
  }
}

struct LiveNotificationPermissionSection: View {
  @ObservedObject var viewModel: LiveNotificationSettingsViewModel

  var body: some View {
    LiveSection {
      switch viewModel.permissionStatus {
      case .unknown:
        LabeledContent("Status") { Text("Unavailable") }
      case .notDetermined:
        Button {
          Task { await viewModel.requestPermission() }
        } label: {
          HStack {
            Text("Allow notifications")
            Spacer()
            if viewModel.isRequestingPermission { ProgressView() }
          }
        }
        .disabled(viewModel.isRequestingPermission)
      case .granted, .provisional, .ephemeral:
        Label("Notifications allowed", systemImage: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case .denied:
        VStack(alignment: .leading, spacing: 8) {
          Label("Notifications are off for TypeType in iOS", systemImage: "bell.slash")
          Button("Open iOS Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          }
        }
      }
    } header: {
      Text("On this device").liveSettingsHeader()
    }
  }
}
