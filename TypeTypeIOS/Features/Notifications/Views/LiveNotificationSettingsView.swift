import SwiftUI

struct LiveNotificationSettingsView: View {
  @StateObject private var viewModel: LiveNotificationSettingsViewModel

  init(dependencies: AppDependencies) {
    _viewModel = StateObject(
      wrappedValue: LiveNotificationSettingsViewModel(
        service: dependencies.pushNotificationsService
          ?? StubPushNotificationSettingsService()
      )
    )
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        ProgressView("Loading notification settings")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case let .failed(message):
        ContentUnavailableView {
          Label("Settings unavailable", systemImage: "bell.slash")
        } description: {
          Text(message)
        } actions: {
          Button("Try again") {
            Task { await viewModel.reload() }
          }
        }
      case .loaded:
        settingsList
      }
    }
    .background(DemoTheme.background)
    .navigationTitle("Channel notifications")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.prepare() }
    .alert(
      "Notification settings",
      isPresented: errorBinding
    ) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.notification-settings.screen")
  }

  @ViewBuilder
  private var settingsList: some View {
    let preferences = viewModel.sortedPreferences
    if preferences.isEmpty {
      ContentUnavailableView(
        "No channel settings",
        systemImage: "bell",
        description: Text("Notification preferences appear after you subscribe to a channel.")
      )
    } else {
      List {
        ForEach(preferences) { preference in
          Toggle(isOn: binding(for: preference)) {
            VStack(alignment: .leading, spacing: 4) {
              Text(Self.channelName(preference.channelURL))
                .foregroundStyle(.primary)
                .lineLimit(1)
              Text(preference.channelURL)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
          .disabled(
            viewModel.updatingURLs.contains(preference.channelURL)
          )
          .accessibilityIdentifier(
            "live.notification-settings.\(preference.channelURL)"
          )
        }
      }
      .listStyle(.insetGrouped)
    }
  }

  private func binding(
    for preference: LiveChannelNotificationPreference
  ) -> Binding<Bool> {
    Binding(
      get: { preference.enabled },
      set: { enabled in
        Task { await viewModel.setEnabled(enabled, for: preference) }
      }
    )
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }

  private static func channelName(_ channelURL: String) -> String {
    let name = URL(string: channelURL)?.lastPathComponent
    guard let name, !name.isEmpty else { return channelURL }
    return name
  }
}

private struct StubPushNotificationSettingsService: LivePushNotificationsServiceProtocol {
  func channelPreferences() async throws -> [LiveChannelNotificationPreference] {
    throw NetworkError.missingServerURL
  }

  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference {
    throw NetworkError.missingServerURL
  }
}
