import Foundation

@MainActor
final class LiveAdminSettingsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published var draft: LiveAdminSettings?
  @Published private(set) var isSaving = false
  @Published private(set) var message: String?
  @Published private(set) var errorMessage: String?

  private let service: LiveAdminServiceProtocol
  private var saved: LiveAdminSettings?

  init(service: LiveAdminServiceProtocol) {
    self.service = service
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
      let value = try await service.settings()
      saved = value
      draft = value
      state = .loaded
    } catch {
      state = .failed(text(for: error))
    }
  }

  func save() async {
    guard !isSaving, let draft, hasChanges else { return }
    isSaving = true
    defer { isSaving = false }
    do {
      let updated = try await service.updateSettings(draft)
      saved = updated
      self.draft = updated
      message = "Instance settings saved"
    } catch {
      errorMessage = text(for: error)
    }
  }

  func reset() {
    draft = saved
  }

  func dismissError() {
    errorMessage = nil
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Admin settings could not be updated."
  }
}
