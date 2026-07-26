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
  @Published var draft = LiveSettings()
  @Published private(set) var isSaving = false
  @Published private(set) var message: String?
  @Published private(set) var errorMessage: String?

  private let service: LiveSettingsServiceProtocol
  private let serviceSelection: LiveServiceSelection
  private let deArrowStore: LiveDeArrowStore
  private var saved = LiveSettings()

  init(
    service: LiveSettingsServiceProtocol,
    serviceSelection: LiveServiceSelection,
    deArrowStore: LiveDeArrowStore
  ) {
    self.service = service
    self.serviceSelection = serviceSelection
    self.deArrowStore = deArrowStore
  }

  var hasChanges: Bool {
    draft != saved
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
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

  func save() async {
    guard !isSaving, hasChanges else { return }
    isSaving = true
    defer { isSaving = false }
    do {
      let updated = try await service.update(draft)
      saved = updated
      draft = updated
      serviceSelection.synchronize(with: updated)
      deArrowStore.invalidatePreferences()
      message = "Settings saved"
    } catch {
      errorMessage = text(for: error)
    }
  }

  func resetDraft() {
    draft = saved
  }

  func dismissError() {
    errorMessage = nil
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Settings could not be updated."
  }
}
