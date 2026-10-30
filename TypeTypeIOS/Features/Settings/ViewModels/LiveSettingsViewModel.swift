import Foundation

@MainActor
final class LiveSettingsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published var draft = LiveSettings() {
    didSet { scheduleSave() }
  }
  @Published private(set) var errorMessage: String?

  private let service: LiveSettingsServiceProtocol
  private let serviceSelection: LiveServiceSelection
  private let deArrowStore: LiveDeArrowStore
  private let onSaved: @MainActor (LiveSettings) -> Void
  private let saveDelay: Duration
  private var saved = LiveSettings()
  private var saveTask: Task<Void, Never>?

  init(
    service: LiveSettingsServiceProtocol,
    serviceSelection: LiveServiceSelection,
    deArrowStore: LiveDeArrowStore,
    saveDelay: Duration = .milliseconds(500),
    onSaved: @escaping @MainActor (LiveSettings) -> Void = { _ in }
  ) {
    self.service = service
    self.serviceSelection = serviceSelection
    self.deArrowStore = deArrowStore
    self.saveDelay = saveDelay
    self.onSaved = onSaved
  }

  deinit {
    saveTask?.cancel()
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    saveTask?.cancel()
    state = .loading
    do {
      let settings = try await service.settings()
      saved = settings
      draft = settings
      serviceSelection.synchronize(with: settings)
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func scheduleSave() {
    guard state == .loaded, draft != saved else { return }
    let previous = saveTask
    previous?.cancel()
    saveTask = Task { [weak self, saveDelay] in
      await previous?.value
      do {
        try await Task.sleep(for: saveDelay)
      } catch {
        return
      }
      await self?.save()
    }
  }

  private func save() async {
    let sent = draft
    guard sent != saved else { return }
    do {
      let updated = try await service.update(sent)
      saved = updated
      if draft == sent {
        draft = updated
      }
      serviceSelection.synchronize(with: updated)
      deArrowStore.invalidatePreferences()
      onSaved(updated)
    } catch {
      guard !Task.isCancelled, draft == sent else { return }
      AppLogger.app.failure("Saving the settings", error)
      draft = saved
      errorMessage = text(for: error)
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? String(localized: "Settings could not be updated.")
  }
}
