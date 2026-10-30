import SwiftUI

struct LiveNotificationSettingsView: View {
  @Environment(\.liveToasts) private var toasts
  @State private var subscriptions: [String: LiveSubscription] = [:]
  @State private var search = ""
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
    content
      .background(LiveThemeBackground().ignoresSafeArea())
      .navigationTitle("Channel notifications")
      .navigationBarTitleDisplayMode(.inline)
      .task { await prepare() }
      .onChange(of: viewModel.toast) { _, toast in
        guard let toast else { return }
        toasts?.show(LiveNotificationTexts.message(for: toast))
        viewModel.dismissToast()
      }
      .alert("Notification settings", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.notification-settings.screen")
  }

  @ViewBuilder
  private var content: some View {
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
        Button("Try again") { Task { await viewModel.reload() } }
      }
    case .loaded:
      settingsList
    }
  }

  @ViewBuilder
  private var settingsList: some View {
    let channels = sortedChannels
    List {
      LiveNotificationPermissionSection(viewModel: viewModel)
      if viewModel.preferences.isEmpty {
        LiveSection {
          Text("Notification choices appear once you subscribe to a channel.")
            .foregroundStyle(.secondary)
        }
      } else {
        LiveNotificationChannelsSection(viewModel: viewModel, channels: channels)
      }
    }
    .liveGroupedList()
    .modifier(ChannelSearch(isOn: viewModel.preferences.count > 12, text: $search))
  }

  private var sortedChannels: [LiveNotificationChannel] {
    let channels = viewModel.preferences.map { preference in
      LiveNotificationChannel(preference: preference, subscription: subscriptions[preference.channelURL])
    }
    let query = search.trimmingCharacters(in: .whitespaces)
    return channels
      .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  private func prepare() async {
    await viewModel.prepare()
    guard let list = try? await subscriptionsService.subscriptions() else { return }
    subscriptions = Dictionary(list.map { ($0.channelURL, $0) }, uniquingKeysWith: { first, _ in first })
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}

private struct ChannelSearch: ViewModifier {
  let isOn: Bool
  @Binding var text: String

  func body(content: Content) -> some View {
    if isOn {
      content.searchable(text: $text, prompt: Text("Search channels"))
    } else {
      content
    }
  }
}
