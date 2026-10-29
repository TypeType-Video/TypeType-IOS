import SwiftUI

struct LiveNotificationSettingsView: View {
  @Environment(\.themePalette) private var palette
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
        TypeTypeSkeletonList(layout: .settings, count: 6)
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
    .background(DemoThemeBackground().ignoresSafeArea())
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
    .overlay { toastOverlay }
    .animation(.easeIn(duration: 0.18), value: viewModel.toast)
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
      List {
        permissionSection
        emptyPreferencesSection
      }
      .liveGroupedList()
    } else {
      List {
        permissionSection
        Section {
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
            .liveRowFill()
            .disabled(
              viewModel.isBulkUpdating
                || viewModel.updatingURLs.contains(preference.channelURL)
            )
            .accessibilityIdentifier(
              "live.notification-settings.\(preference.channelURL)"
            )
          }
        } header: {
          channelSectionHeader
        } footer: {
          Text(viewModel.budgetFooterText)
            .accessibilityIdentifier("live.notification-settings.budget")
        }
      }
        .liveGroupedList()
    }
  }

  /// "Enable all"/"Disable all" beside the styled caption; the remaining
  /// polling budget is spelled out in the section footer below.
  private var channelSectionHeader: some View {
    HStack(spacing: 12) {
      Text("Channel notifications").liveSectionHeader()
      bulkButton(
        "Enable all",
        enabled: viewModel.canEnableAll
      ) {
        Task { await viewModel.setAllEnabled(true) }
      }
      .accessibilityIdentifier("live.notification-settings.enable-all")
      bulkButton(
        "Disable all",
        enabled: viewModel.canDisableAll
      ) {
        Task { await viewModel.setAllEnabled(false) }
      }
      .accessibilityIdentifier("live.notification-settings.disable-all")
    }
  }

  private func bulkButton(
    _ title: String,
    enabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(enabled ? palette.accent : Color.secondary)
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
  }

  @ViewBuilder
  private var permissionSection: some View {
    Section {
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
    } header: { Text("iOS permissions").liveSectionHeader() }
  }

  @ViewBuilder
  private var emptyPreferencesSection: some View {
    Section {
      Text("Notification preferences appear after you subscribe to a channel.")
        .foregroundStyle(.secondary)
    }
  }

  /// Center glass card (the favourites toast pattern): symbol, message,
  /// swipe-to-dismiss with a slow fade, plus the auto-dismiss timer.
  private func toastCard(
    _ toast: LiveNotificationSettingsViewModel.Toast
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: toast.systemImage)
        .font(.title3.weight(.semibold))
        .foregroundStyle(palette.accent)
      Text(toast.message)
        .font(.callout.weight(.semibold))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 16)
    .transition(.opacity)
    .gesture(
      DragGesture(minimumDistance: 24)
        .onEnded { _ in
          withAnimation(.easeOut(duration: 0.6)) {
            viewModel.dismissToast()
          }
        }
    )
    .task(id: toast) {
      try? await Task.sleep(for: .seconds(2.6))
      withAnimation(.easeOut(duration: 0.35)) {
        viewModel.dismissToast()
      }
    }
    .accessibilityIdentifier("live.notification-settings.toast")
  }

  @ViewBuilder
  private var toastOverlay: some View {
    if let toast = viewModel.toast {
      if #available(iOS 26.0, *) {
        toastCard(toast)
          .glassEffect(.regular, in: .capsule)
      } else {
        toastCard(toast)
          .background(.black.opacity(0.85), in: Capsule())
      }
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
