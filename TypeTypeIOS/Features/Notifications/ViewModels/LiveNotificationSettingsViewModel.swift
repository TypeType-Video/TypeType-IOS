import Foundation

@MainActor
final class LiveNotificationSettingsViewModel: ObservableObject {
  enum Toast: Equatable {
    case turnedOn(Int)
    case turnedOff(Int)
  }

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
  @Published private(set) var permissionStatus = LiveNotificationPermissionStatus.unknown
  @Published private(set) var isRequestingPermission = false
  @Published private(set) var toast: Toast?
  @Published private(set) var isBulkUpdating = false

  private let service: LivePushNotificationsServiceProtocol
  private let permissionManager: LiveNotificationPermissionManaging?

  init(
    service: LivePushNotificationsServiceProtocol,
    permissionManager: LiveNotificationPermissionManaging? = nil
  ) {
    self.service = service
    self.permissionManager = permissionManager
  }

  var sortedPreferences: [LiveChannelNotificationPreference] {
    preferences.sorted {
      $0.channelURL.localizedCaseInsensitiveCompare(
        $1.channelURL
      ) == .orderedAscending
    }
  }

  var canEnableAll: Bool {
    preferences.contains(where: { !$0.enabled }) && !isBulkUpdating
  }

  var canDisableAll: Bool {
    preferences.contains(where: { $0.enabled }) && !isBulkUpdating
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
    await loadPermission()
  }

  func loadPermission() async {
    guard let permissionManager else {
      permissionStatus = .unknown
      return
    }
    permissionStatus = await permissionManager.currentStatus()
  }

  func requestPermission() async {
    guard let permissionManager,
      !isRequestingPermission
    else {
      return
    }
    isRequestingPermission = true
    defer { isRequestingPermission = false }

    do {
      permissionStatus = try await permissionManager.requestAuthorization()
    } catch {
      errorMessage = String(localized: "iOS notification permission could not be requested.")
    }
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

  func setEnabled(
    _ enabled: Bool,
    for preference: LiveChannelNotificationPreference
  ) async {
    guard !isBulkUpdating,
      !updatingURLs.contains(preference.channelURL)
    else {
      return
    }
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

  func setAllEnabled(_ enabled: Bool) async {
    guard !isBulkUpdating else { return }
    let targets = sortedPreferences.filter { $0.enabled != enabled }
    guard !targets.isEmpty else { return }

    let appliedTargets = targets
    isBulkUpdating = true
    defer { isBulkUpdating = false }

    for preference in appliedTargets {
      if let index = indexOf(preference) {
        preferences[index].enabled = enabled
      }
    }

    do {
      let updated = try await service.setChannelPreferences(
        enabled: enabled,
        channelURLs: appliedTargets.map(\.channelURL)
      )
      for preference in updated {
        if let index = indexOf(preference) {
          preferences[index] = preference
        }
      }
    } catch {
      await resync()
      errorMessage = Self.message(for: error)
      return
    }

    toast = enabled ? .turnedOn(appliedTargets.count) : .turnedOff(appliedTargets.count)
  }

  func dismissError() {
    errorMessage = nil
  }

  func dismissToast() {
    toast = nil
  }

  private func isCurrentlyEnabled(
    _ preference: LiveChannelNotificationPreference
  ) -> Bool {
    guard let index = indexOf(preference) else {
      return preference.enabled
    }
    return preferences[index].enabled
  }

  // Resync without touching `state`: no skeleton flash after a failed batch.
  private func resync() async {
    if let fresh = try? await service.channelPreferences() {
      preferences = fresh
    }
  }

  private func indexOf(
    _ preference: LiveChannelNotificationPreference
  ) -> Array<LiveChannelNotificationPreference>.Index? {
    preferences.firstIndex { $0.channelURL == preference.channelURL }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? String(localized: "Notification settings could not be updated.")
  }
}
