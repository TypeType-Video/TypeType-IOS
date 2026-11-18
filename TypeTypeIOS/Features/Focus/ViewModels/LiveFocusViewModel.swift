import Foundation

@MainActor
final class LiveFocusViewModel: ObservableObject {
  @Published private(set) var settings: LiveFocusSettings?
  @Published private(set) var groups: [LiveSubscriptionGroup] = []
  @Published private(set) var isSaving = false
  @Published private(set) var error: String?

  private let service: LiveFocusServiceProtocol
  private let subscriptions: LiveSubscriptionsServiceProtocol
  private let timezone: () -> String

  init(
    service: LiveFocusServiceProtocol, subscriptions: LiveSubscriptionsServiceProtocol,
    timezone: @escaping () -> String = { TimeZone.current.identifier }
  ) {
    self.service = service
    self.subscriptions = subscriptions
    self.timezone = timezone
  }

  var isLocked: Bool { settings?.enabled == true }

  func load() async {
    async let loadedGroups = try? subscriptions.groups()
    do {
      settings = try await service.settings()
      error = nil
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "Focus could not be loaded.")
    }
    groups = await loadedGroups ?? []
  }

  func setEntertainment(_ id: String) async { await change(LiveFocusRequest(enabled: false, entertainmentGroupID: id)) }
  func setStudy(_ id: String) async { await change(LiveFocusRequest(enabled: false, studyGroupID: id)) }
  func setTransition(_ days: Int) async { await change(LiveFocusRequest(enabled: false, transitionDays: days)) }
  func setArchive(_ days: Int) async { await change(LiveFocusRequest(enabled: false, archiveDays: days)) }

  func setSchedule(_ schedule: LiveFocusSettings.Schedule) async {
    await change(LiveFocusRequest(enabled: false, schedule: schedule, timezone: timezone()))
  }

  func turnOn() async { await save(LiveFocusRequest(enabled: true)) }
  func turnOff() async { await save(LiveFocusRequest(enabled: false)) }

  private func change(_ request: LiveFocusRequest) async {
    guard !isLocked else { return }
    await save(request)
  }

  private func save(_ request: LiveFocusRequest) async {
    isSaving = true
    defer { isSaving = false }
    do {
      settings = try await service.save(request)
      error = nil
    } catch {
      self.error = LiveUserError(error).message ?? String(localized: "The change could not be saved.")
    }
  }
}
