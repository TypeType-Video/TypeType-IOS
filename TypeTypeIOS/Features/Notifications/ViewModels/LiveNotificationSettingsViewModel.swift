import Foundation

@MainActor
final class LiveNotificationSettingsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var preferences: [LiveChannelNotificationPreference] = []
  @Published private(set) var errorMessage: String?
  @Published private(set) var updatingURLs: Set<String> = []

  private let service: LivePushNotificationsServiceProtocol

  init(service: LivePushNotificationsServiceProtocol) {
    self.service = service
  }

  var sortedPreferences: [LiveChannelNotificationPreference] {
    preferences.sorted {
      $0.channelURL.localizedCaseInsensitiveCompare(
        $1.channelURL
      ) == .orderedAscending
    }
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      preferences = try await service.channelPreferences()
      state = .loaded
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func setEnabled(_ enabled: Bool, for preference: LiveChannelNotificationPreference) async {
    guard !updatingURLs.contains(preference.channelURL) else { return }
    updatingURLs.insert(preference.channelURL)

    if let index = indexOf(preference) {
      preferences[index].enabled = enabled
    }
    defer {
      updatingURLs.remove(preference.channelURL)
    }

    do {
      let updated = try await service.setChannelPreference(
        channelURL: preference.channelURL,
        enabled: enabled
      )
      if let index = indexOf(preference) {
        preferences[index] = updated
      }
    } catch {
      if let index = indexOf(preference) {
        preferences[index].enabled = preference.enabled
      }
      errorMessage = Self.message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func indexOf(
    _ preference: LiveChannelNotificationPreference
  ) -> Array<LiveChannelNotificationPreference>.Index? {
    preferences.firstIndex { $0.channelURL == preference.channelURL }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Notification settings could not be updated."
  }
}
