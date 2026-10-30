import Combine
import Foundation

@MainActor
final class LiveServiceSelection: ObservableObject {
  @Published private(set) var selectedID: Int
  @Published private(set) var services: [VideoService]
  @Published private(set) var errorMessage: String?

  private enum Storage {
    static let selectedID = "live.selected-video-service"
  }

  private let settingsService: LiveSettingsServiceProtocol
  private let defaults: UserDefaults
  private var supportedServiceIDs = [0]
  private var refreshTask: Task<Void, Never>?

  init(
    settingsService: LiveSettingsServiceProtocol,
    defaults: UserDefaults = .standard
  ) {
    self.settingsService = settingsService
    self.defaults = defaults
    let cachedID = defaults.object(forKey: Storage.selectedID) as? Int ?? 0
    selectedID = cachedID
    services = [VideoService.service(for: 0)]
  }

  func configure(supportedServiceIDs: [Int]) {
    let resolved = VideoService.supported(supportedServiceIDs)
    services = resolved.isEmpty
      ? [VideoService.service(for: 0)]
      : resolved
    self.supportedServiceIDs = services.map(\.id)
    apply(selectedID)
  }

  func refresh() async {
    refreshTask?.cancel()
    let task = Task { [settingsService] in
      do {
        let settings = try await settingsService.settings()
        guard !Task.isCancelled else { return }
        apply(settings.defaultService)
        errorMessage = nil
      } catch is CancellationError {
        return
      } catch {
        errorMessage = Self.message(for: error)
      }
    }
    refreshTask = task
    await task.value
  }

  // Applied before the save so the feed switches at once; a refused save puts the previous service back.
  func select(_ serviceID: Int) async {
    guard supportedServiceIDs.contains(serviceID) else { return }
    guard selectedID != serviceID else { return }
    let previousID = selectedID
    apply(serviceID)
    do {
      var settings = try await settingsService.settings()
      settings.defaultService = serviceID
      let updated = try await settingsService.update(settings)
      guard selectedID == serviceID else { return }
      apply(updated.defaultService)
      errorMessage = nil
    } catch {
      guard selectedID == serviceID else { return }
      apply(previousID)
      errorMessage = Self.message(for: error)
    }
  }

  func synchronize(with settings: LiveSettings) {
    apply(settings.defaultService)
  }

  func dismissError() {
    errorMessage = nil
  }

  private func apply(_ candidateID: Int) {
    let resolvedID = supportedServiceIDs.contains(candidateID)
      ? candidateID
      : supportedServiceIDs.first ?? 0
    selectedID = resolvedID
    defaults.set(resolvedID, forKey: Storage.selectedID)
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The default service could not be updated."
  }
}
