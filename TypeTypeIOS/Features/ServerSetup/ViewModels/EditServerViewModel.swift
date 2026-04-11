import Combine
import Foundation

@MainActor
final class EditServerViewModel: ObservableObject {
  let serverID: String
  @Published var serverName: String
  @Published var serverURL: String
  @Published var errorMessage: String?
  @Published var isSaving: Bool = false

  init(server: ServerProfile) {
    serverID = server.id
    serverName = server.name
    serverURL = server.baseURLString
  }

  func submit(using coordinator: RootCoordinator) async -> Bool {
    isSaving = true
    errorMessage = nil
    do {
      try await coordinator.updateServer(id: serverID, name: serverName, urlInput: serverURL)
      isSaving = false
      return true
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to update server."
    } catch {
      errorMessage = "Unable to update server."
    }
    isSaving = false
    return false
  }
}
