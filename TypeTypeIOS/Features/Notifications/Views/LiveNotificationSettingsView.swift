import SwiftUI

struct LiveNotificationSettingsView: View {
  @State private var channelNames: [String: String] = [:]
  @StateObject private var viewModel: LiveNotificationSettingsViewModel
  private let subscriptionsService: LiveSubscriptionsServiceProtocol

  init(dependencies: AppDependencies) {
    subscriptionsService = dependencies.subscriptionsService
    _viewModel = StateObject(
      wrappedValue: LiveNotificationSettingsViewModel(
        service: dependencies.pushNotificationsService
          ?? StubPushNotificationSettingsService(),
        permissionManager: dependencies.notificationPermissionManager
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
    .task { await viewModel.prepare()
      if let subscriptions = try? await subscriptionsService
        .subscriptions() {
        channelNames = Dictionary(
          subscriptions.map { ($0.channelURL, $0.name) },
          uniquingKeysWith: { first, _ in first }
        )
      } }
    .onChange(of: viewModel.permissionStatus) { }
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
      ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        permissionSection
        emptyPreferencesSection
      }
      .background(DemoTheme.pageBackground)
    }
      .listStyle(.insetGrouped)
    } else {
      List {
        permissionSection
        ForEach(preferences) { preference in
          Toggle(isOn: binding(for: preference)) {
            VStack(alignment: .leading, spacing: 4) {
              Text(
                channelNames[preference.channelURL]
                  ?? Self.channelName(preference.channelURL)
              )
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

  @ViewBuilder
  private var permissionSection: some View {
    LiveSettingsSection("iOS permissions") {
      switch viewModel.permissionStatus {
      case .unknown:
        LabeledContent("Status", value: "Unavailable")
      case .notDetermined:
        Button {
          Task { await viewModel.requestPermission() }
        } label: {
          if viewModel.isRequestingPermission {
            HStack {
              Text("Request permission")
              Spacer()
              ProgressView()
            }
          } else {
            Text("Enable iOS notifications")
          }
        }
        .disabled(viewModel.isRequestingPermission)
      case .granted, .provisional, .ephemeral:
        Label("Notifications enabled", systemImage: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case .denied:
        VStack(alignment: .leading, spacing: 8) {
          Label("Notifications disabled", systemImage: "bell.slash")
          Button("Open iOS Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var emptyPreferencesSection: some View {
    LiveSettingsCard {
      Text("Notification preferences appear after you subscribe to a channel.")
        .foregroundStyle(.secondary)
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
