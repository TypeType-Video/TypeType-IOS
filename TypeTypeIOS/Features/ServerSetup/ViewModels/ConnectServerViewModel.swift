import Combine
import Foundation

@MainActor
final class ConnectServerViewModel: ObservableObject {
  @Published var serverName: String = ""
  @Published var serverURL: String = ""
  @Published var errorMessage: String?
  @Published var isSaving: Bool = false

  func submit(using coordinator: RootCoordinator) async -> Bool {
    isSaving = true
    errorMessage = nil
    do {
      try await coordinator.addServer(name: serverName, urlInput: serverURL)
      serverName = ""
      serverURL = ""
      isSaving = false
      return true
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to save server."
    } catch {
      errorMessage = "Unable to save server."
    }
    isSaving = false
    return false
  }
}
